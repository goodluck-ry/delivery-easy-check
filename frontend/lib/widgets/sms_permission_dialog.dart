// 短信权限解释弹窗：首次/未授权时引导用户授权。
//
// 主提示 + 「我们为什么需要」按钮展开解释 + 同意/不同意并退出。
// 用户点「同意并授权」返回 true（调用方再弹系统授权窗）；
// 「不同意并退出」返回 false（调用方退出应用，因这是必要权限）。
// 调用方应设 barrierDismissible: false，禁止点外部取消。

import 'package:flutter/material.dart';

class SmsPermissionRationaleDialog extends StatefulWidget {
  const SmsPermissionRationaleDialog({super.key});

  @override
  State<SmsPermissionRationaleDialog> createState() =>
      _SmsPermissionRationaleDialogState();
}

class _SmsPermissionRationaleDialogState
    extends State<SmsPermissionRationaleDialog> {
  bool _showRationale = false;

  // 展开后的三段解释：核心功能所需 / 精准过滤范围 / 隐私安全。
  Widget _buildRationale() {
    const titleStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 13);
    const bodyStyle = TextStyle(fontSize: 13, color: Colors.black87);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text.rich(TextSpan(children: [
          TextSpan(text: '1. 核心功能所需：', style: titleStyle),
          TextSpan(
            text: '本应用为纯本地工具，需要通过读取短信为您自动识别并生成"快递卡片"。若不授权，应用将无法自动提取取件码。',
            style: bodyStyle,
          ),
        ])),
        const SizedBox(height: 8),
        const Text.rich(TextSpan(children: [
          TextSpan(text: '2. 精准过滤范围：', style: titleStyle),
          TextSpan(
            text: '读取范围严格限定在短信收件箱内，且仅识别包含特定快递关键词（如取件码、菜鸟、丰巢等）的短信，绝不读取或处理您的个人私密短信。',
            style: bodyStyle,
          ),
        ])),
        const SizedBox(height: 8),
        const Text.rich(TextSpan(children: [
          TextSpan(text: '3. 关注您的隐私安全：', style: titleStyle),
          TextSpan(
            text: '所有解析均在手机本地完成。我们不保存短信原文、不上传云端、不外发，您的数据完全留存在您自己的设备中。',
            style: bodyStyle,
          ),
        ])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('读取短信权限'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('该应用正常使用需要读取您的短信。'),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: () =>
                    setState(() => _showRationale = !_showRationale),
                child: Text(_showRationale
                    ? '收起说明'
                    : '我们为什么要获取读取您短信的权限？'),
              ),
            ),
            if (_showRationale) ...[
              const SizedBox(height: 4),
              _buildRationale(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('不同意并退出'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('同意并授权'),
        ),
      ],
    );
  }
}
