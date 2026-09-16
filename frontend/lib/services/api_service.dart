// 后端 API 封装。所有 HTTP 调用集中在这里，统一走 _post/_get 带超时。
// 后端基地址：本机 FastAPI（127.0.0.1:8000）。

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/express_info.dart';

class ApiService {
  static const _base = 'http://127.0.0.1:8000';
  static const _timeout = Duration(seconds: 10);

  /// 统一 POST：带超时
  Future<http.Response> _post(String path, Map<String, dynamic> body) {
    return http.post(
      Uri.parse('$_base$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(_timeout);
  }

  /// 统一 GET：带超时
  Future<http.Response> _get(String path) {
    return http.get(Uri.parse('$_base$path')).timeout(_timeout);
  }

  /// 请求验证码。本地模拟阶段后端直接回传 code。
  Future<String> requestCode(String phone) async {
    final r = await _post('/api/auth/request_code', {'phone': phone});
    if (r.statusCode != 200) throw Exception('请求验证码失败：${r.body}');
    return jsonDecode(r.body)['code'] as String;
  }

  /// 校验验证码并绑定到 device_id。成功返回 true。
  Future<bool> verifyCode(String phone, String code, String deviceId) async {
    final r = await _post('/api/auth/verify_code',
        {'phone': phone, 'code': code, 'device_id': deviceId});
    return r.statusCode == 200;
  }

  /// 查本设备已绑定的手机号列表（只取 verified==1，与后端 _bound_phones 一致）。
  Future<List<String>> bindings(String deviceId) async {
    final r = await _get('/api/auth/bindings?device_id=$deviceId');
    if (r.statusCode != 200) throw Exception('查绑定失败：${r.body}');
    final list = jsonDecode(r.body) as List;
    return list
        .where((e) => e['verified'] == 1)
        .map((e) => e['phone'] as String)
        .toList();
  }

  /// 解绑手机号。
  Future<void> unbind(String deviceId, String phone) async {
    final r = await _post('/api/auth/unbind', {'device_id': deviceId, 'phone': phone});
    if (r.statusCode != 200) throw Exception('解绑失败：${r.body}');
  }

  /// 查本设备绑定号下的未取件快递。
  Future<List<ExpressInfo>> query(String deviceId) async {
    final r = await _get('/api/express/query?device_id=$deviceId');
    if (r.statusCode != 200) throw Exception('查询失败：${r.body}');
    final list = jsonDecode(r.body) as List;
    return list
        .map((e) => ExpressInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 更新某条快递的取件状态。
  Future<void> updateStatus(int id, int status, String deviceId) async {
    final r = await _post('/api/express/update_status',
        {'id': id, 'status': status, 'device_id': deviceId});
    if (r.statusCode != 200) throw Exception('更新状态失败：${r.body}');
  }
}
