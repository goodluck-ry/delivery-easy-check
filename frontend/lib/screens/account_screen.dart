// 账号设置页：管理本机绑定的手机号。
// 绑定流程：点「绑定新号」→ 弹 Dialog 输手机号+验证码 → 绑定成功关闭。

import 'package:flutter/material.dart';

import '../app_config.dart';
import '../services/auth_store.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.enableBindFlow) {
      return Scaffold(
        appBar: AppBar(title: const Text('账号设置')),
        body: const Center(
          child: Text('账号功能未启用', style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('账号设置')),
      body: ListenableBuilder(
        listenable: authStore,
        builder: (context, _) {
          final phones = authStore.bindings;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('已绑定手机号',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('绑定新号'),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => const _BindDialog(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (phones.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('尚未绑定手机号，绑定后才能查看快递',
                      style: TextStyle(color: Colors.grey)),
                )
              else
                ...phones.map((p) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.phone_android),
                        title: Text(p),
                        trailing: TextButton(
                          onPressed: () => _confirmUnbind(context, p),
                          child: const Text('解绑',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ),
                    )),
              const Divider(height: 32),
              // 显示本机 device_id，方便在 /docs 手动测试时复制
              if (authStore.deviceId != null)
                Text(
                  '本机标识：${authStore.deviceId}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmUnbind(BuildContext context, String phone) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('解绑确认'),
        content: Text('确定解绑 $phone 吗？解绑后该号的快递将不再显示。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('解绑')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await authStore.unbind(phone);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('解绑失败：$e')));
      }
    }
  }
}

// 绑定对话框：输手机号 → 获取验证码（本地模拟自动回填）→ 输码 → 绑定。
class _BindDialog extends StatefulWidget {
  const _BindDialog();

  @override
  State<_BindDialog> createState() => _BindDialogState();
}

class _BindDialogState extends State<_BindDialog> {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return _toast('请输入手机号');
    setState(() => _busy = true);
    try {
      final code = await authStore.requestCode(phone);
      _codeCtrl.text = code; // 本地模拟：直接回填方便调试
      _toast('验证码已生成（本地模拟）：$code');
    } catch (e) {
      _toast('请求失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _bind() async {
    final phone = _phoneCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    if (phone.isEmpty || code.isEmpty) return _toast('请输入手机号和验证码');
    setState(() => _busy = true);
    try {
      final ok = await authStore.bind(phone, code);
      if (ok) {
        if (mounted) Navigator.pop(context); // 绑定成功关闭 Dialog，列表由 authStore 自动刷新
        _toast('绑定成功');
      } else {
        _toast('验证码错误');
      }
    } catch (e) {
      _toast('绑定失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('绑定新手机号'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: '手机号',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '验证码',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _busy ? null : _requestCode,
                child: const Text('获取验证码'),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _busy ? null : _bind,
          child: const Text('绑定'),
        ),
      ],
    );
  }
}
