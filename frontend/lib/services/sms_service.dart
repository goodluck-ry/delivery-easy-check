// 短信服务：封装权限申请与收件箱读取（DAY5）。
//
// task 23：权限申请（permission_handler 检查 + 请求 READ_SMS）。
// task 24：收件箱读取（telephony.getInboxSms + 关键字粗筛）+ 权限触发流程。
// 体验改：readInbox 按 sinceMs 时间戳下沉过滤（SmsFilter，SQL 层）；
//         粗筛改为必须含"取件"或"凭"（排除"云朵清零"等无关提醒）。
// 受 AppConfig.enableLocalSms 开关控制。

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:telephony/telephony.dart';

import '../widgets/sms_permission_dialog.dart';

class SmsService {
  SmsService._();
  static final SmsService instance = SmsService._();

  final _telephony = Telephony.instance;

  /// 是否已授予短信权限。
  Future<bool> get hasPermission async {
    final status = await Permission.sms.status;
    return status.isGranted;
  }

  /// 请求短信权限（弹系统授权窗）。返回是否最终授权。
  Future<bool> requestPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  /// 权限触发流程：已授权直接返回 true；未授权先弹解释窗，
  /// 用户同意则请求系统权限，不同意返回 false（调用方应退出应用）。
  Future<bool> ensurePermission(BuildContext context) async {
    if (await hasPermission) return true;
    // 调用方（widget）负责保证传入的 context 在 await 后仍有效。
    final agreed = await showDialog<bool>(
          // ignore: use_build_context_synchronously
          context: context,
          barrierDismissible: false,
          builder: (_) => const SmsPermissionRationaleDialog(),
        ) ??
        false;
    if (!agreed) return false;
    return requestPermission();
  }

  /// 读取收件箱：按 sinceMs 时间戳下沉过滤（telephony SmsFilter，SQL 层）
  /// + 粗筛（必须含"取件"或"凭"才视作快递短信）。调用前应先 ensurePermission。
  Future<List<SmsMessage>> readInbox({required int sinceMs}) async {
    final filter = SmsFilter.where(SmsColumn.DATE)
        .greaterThanOrEqualTo(sinceMs.toString());
    final all = await _telephony.getInboxSms(filter: filter);
    return all.where((m) {
      final body = m.body ?? '';
      // 必须含"取件"或"凭"，排除"云朵清零"等无关提醒
      return body.contains('取件') || body.contains('凭');
    }).toList();
  }
}
