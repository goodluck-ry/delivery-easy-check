// 快递短信解析引擎（Dart 版，DAY5 体验改优化）。
//
// 体验改优化（2026-08-02）：
// - 取件码：取消结尾标点强依赖，[A-Za-z0-9\-]+ 容错截断；4 种模式。
// - company：全文枚举匹配，不依赖"您的XX快递"句式。
// - station：只提取"请到/已到..."到达句式后面的原文，不套品牌词、不拼装、不猜。
//   提取不到就为空，由显示层决定怎么展示。

class ParsedSms {
  final String phone;
  final String company;
  final String station;
  final String pickupCode;

  const ParsedSms({
    required this.phone,
    required this.company,
    required this.station,
    required this.pickupCode,
  });

  @override
  String toString() =>
      'ParsedSms(phone=$phone, company=$company, station=$station, pickupCode=$pickupCode)';
}

/// 解析规则注册表：默认规则 + 运行时可追加。
class SmsRules {
  SmsRules._();

  static int _lenDesc(String a, String b) => b.length.compareTo(a.length);

  // 主流快递公司，长前短后。
  static final List<String> companies = [
    "极兔速递", "极兔",
    "顺丰速运", "顺丰",
    "京东物流", "京东",
    "中国邮政", "邮政EMS", "EMS",
    "中通", "圆通", "申通", "韵达",
    "德邦", "丹鸟", "天天", "百世",
    "宅急送", "丰网", "苏宁", "唯品速递",
  ]..sort(_lenDesc);

  // 取件码模式，按优先级依次尝试。容错截断：[A-Za-z0-9\-]+ 到非码字符停，不依赖结尾标点。
  static final List<RegExp> pickupPatterns = [
    RegExp(r'取件码[：:\s]*([A-Za-z0-9\-]+)'), // 取件码：889955 / 取件码 1-2-3004 / 取件码889955
    RegExp(r'凭([A-Za-z0-9\-]+)取件'), // 凭1-2-0345取件
    RegExp(r'([0-9]{1,2}-[0-9]{1,2}-[0-9]{4})'), // 经典分段 1-2-3004（无视前后文）
    RegExp(r'【([A-Za-z0-9\-]+)】'), // 【A-12】带括号码（不匹配中文签名）
  ];

  static RegExp? _companyRe;
  static RegExp get companyRe {
    _companyRe ??= RegExp(companies.join('|'));
    return _companyRe!;
  }

  /// 追加快递公司名（去重，自动按长度降序重排）。
  static void addCompany(String name) {
    if (name.isEmpty || companies.contains(name)) return;
    companies.add(name);
    companies.sort(_lenDesc);
    _companyRe = null;
  }

  /// 追加取件码正则模式（优先级最低，排在默认模式之后）。
  static void addPickupPattern(RegExp pattern) {
    pickupPatterns.add(pattern);
  }
}

// 结构正则（固定语法，非业务规则，保持 const）。
final RegExp _phoneRe = RegExp(r'1[3-9]\d{9}');
final RegExp _signatureRe = RegExp(r'【(.+?)】');

final RegExp _arriveRe =
    RegExp(r'(?:请到|请前往|已送达|已到达|已抵|已到|送达|已放在|放在)(.+?)(?:取件|自提|[，,。])');

/// 解析一条短信，返回 ParsedSms。
ParsedSms parseSms(String sms, {String bindPhone = ''}) {
  sms = sms.trim();

  // 1. 签名【xxx】
  final sigMatch = _signatureRe.firstMatch(sms);
  final signature = sigMatch?.group(1)?.trim() ?? '';

  // 2. company：全文枚举匹配（不依赖"您的XX快递"句式）→ 签名 → 未知
  var company = '';
  final hit = SmsRules.companyRe.firstMatch(sms);
  if (hit != null) {
    company = hit.group(0)!;
  }
  if (company.isEmpty) {
    company = signature.isNotEmpty ? signature : '未知来源快递';
  }

  // 3. phone：短信里有就用，没有用绑定号
  final phMatch = _phoneRe.firstMatch(sms);
  final phone = phMatch?.group(0) ?? bindPhone.trim();

  // 4. station：只提取到达句式后面的原文，不猜
  final station = _parseStation(sms);

  // 5. pickup_code：依次试模式，兜底非空
  var pickupCode = '';
  for (final pat in SmsRules.pickupPatterns) {
    final m = pat.firstMatch(sms);
    if (m != null) {
      pickupCode = m.group(1)!.trim();
      break;
    }
  }
  if (pickupCode.isEmpty) {
    pickupCode = '未知取件码';
  }

  return ParsedSms(
    phone: phone,
    company: company,
    station: station,
    pickupCode: pickupCode,
  );
}

/// 提取取件地点：只取"请到/已到..."句式后面的原文，提取不到返回空。不拼装、不猜。
String _parseStation(String sms) {
  final arrMatch = _arriveRe.firstMatch(sms);
  return arrMatch?.group(1)?.trim() ?? '';
}