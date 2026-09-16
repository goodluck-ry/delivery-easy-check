// sms_parser 移植正确性测试。
// 5 条样例覆盖：取件码【】/取件码：/凭...取件/请联系...取件 四种模式，
// 以及 company 正文提取+签名兜底、station 品牌匹配+通用类型词前缀。

import 'package:flutter_test/flutter_test.dart';
import 'package:campus_express/parsers/sms_parser.dart';

void main() {
  test('样例1：菜鸟签名 + 顺丰正文 + 取件码【】', () {
    const sms = '【菜鸟】您的顺丰快递已到菜鸟驿站东门店，取件码【A-1234】，请及时取件。';
    final r = parseSms(sms);
    expect(r.company, '顺丰');
    expect(r.station, '菜鸟驿站东门店');
    expect(r.pickupCode, 'A-1234');
    expect(r.phone, '');
  });

  test('样例2：中通正文 + 丰巢柜 + 取件码：', () {
    const sms = '【中通快递】您的中通快递已放在丰巢柜北门，取件码：88995523，请取件。';
    final r = parseSms(sms);
    expect(r.company, '中通');
    expect(r.station, '丰巢柜北门');
    expect(r.pickupCode, '88995523');
  });

  test('样例3：韵达 + 驿站无品牌地点 + 凭...取件', () {
    const sms = '【韵达】您的韵达快递已到驿站，凭1-2-0345取件';
    final r = parseSms(sms);
    expect(r.company, '韵达');
    expect(r.station, '驿站');
    expect(r.pickupCode, '1-2-0345');
  });

  test('样例4：京东正文 + 片段无品牌用片段本身 + 请联系...取件', () {
    const sms = '【京东物流】您的京东快递已送达东门前台，请联系前台取件';
    final r = parseSms(sms);
    expect(r.company, '京东物流');
    expect(r.station, '东门前台');
    // 新取件码规则无"请联系...取件"模式，该场景兜底"未知取件码"
    expect(r.pickupCode, '未知取件码');
  });

  test('样例5：拼多多签名兜底 + 兔喜生活 + 取件码：', () {
    const sms = '【拼多多】您的快递已到兔喜生活南门店，取件码：5566，请取件。';
    final r = parseSms(sms);
    expect(r.company, '拼多多');
    expect(r.station, '兔喜生活南门店');
    expect(r.pickupCode, '5566');
  });

  test('phone 优先短信内手机号，无则用绑定号', () {
    const sms = '【顺丰速运】您的顺丰快递已到菜鸟驿站，取件码：1234，电话13800138000。';
    final r = parseSms(sms, bindPhone: '13900000000');
    expect(r.phone, '13800138000');
    final r2 = parseSms('【顺丰速运】您的顺丰快递已到菜鸟驿站，取件码：1234。',
        bindPhone: '13900000000');
    expect(r2.phone, '13900000000');
  });

  test('规则注册表可追加公司并生效', () {
    // 公司名不能含"快递/速递/包裹"子串，否则 bodyRe 非贪婪会提前截断
    SmsRules.addCompany('测试达达');
    const sms = '【某签名】您的测试达达快递已到驿站，取件码：9999。';
    final r = parseSms(sms);
    expect(r.company, '测试达达');
  });
}
