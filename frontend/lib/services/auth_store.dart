// 身份状态管理：device_id 持久化 + 本地绑定号列表。
//
// DAY5 起验证码绑定流程搬前端本地（不再调后端 /api/auth）：
// 本地生成验证码 → 本地校验 → 绑定号存 SharedPreferences。
// 本地模拟阶段，码直接回填给用户方便调试。
// 全局单例 authStore，列表页和账号设置页共享。

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStore extends ChangeNotifier {
  String? _deviceId;
  List<String> _bindings = const [];
  bool _initialized = false;

  // 本地模拟验证码：申请码时生成，校验时比对，内存存（重启需重新申请）。
  String? _pendingPhone;
  String? _pendingCode;

  String? get deviceId => _deviceId;
  List<String> get bindings => _bindings;
  bool get initialized => _initialized;
  bool get hasBinding => _bindings.isNotEmpty;

  /// App 启动时调用：加载或生成 device_id，读本地绑定号列表。
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('device_id');
    if (id == null) {
      id = _newDeviceId();
      await prefs.setString('device_id', id);
    }
    _deviceId = id;
    _bindings = prefs.getStringList('bindings') ?? const [];
    _initialized = true;
    notifyListeners();
  }

  /// 本地生成验证码（模拟收到短信）。返回码供 UI 回填。
  Future<String> requestCode(String phone) async {
    final r = Random.secure();
    final code = List.generate(6, (_) => r.nextInt(10)).join();
    _pendingPhone = phone;
    _pendingCode = code;
    return code;
  }

  /// 本地校验验证码并绑定。成功返回 true。
  Future<bool> bind(String phone, String code) async {
    if (phone != _pendingPhone || code != _pendingCode) return false;
    if (!_bindings.contains(phone)) {
      _bindings = [..._bindings, phone];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('bindings', _bindings);
    }
    _pendingPhone = null;
    _pendingCode = null;
    notifyListeners();
    return true;
  }

  /// 解绑手机号（本地移除）。
  Future<void> unbind(String phone) async {
    _bindings = _bindings.where((p) => p != phone).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('bindings', _bindings);
    notifyListeners();
  }

  /// 生成 32 位 hex 作为 device_id（不引第三方 uuid 包）。
  String _newDeviceId() {
    final r = Random.secure(); // 加密安全随机
    return List.generate(32, (_) => r.nextInt(16).toRadixString(16)).join();
  }
}

final authStore = AuthStore();
