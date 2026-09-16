// 设置页：读取周期等选项，以后可扩展。
// 读取周期：近7天 / 近14天 / 近1个月 / 近6个月 / 自定义（输入天数）。

import 'package:flutter/material.dart';

import '../services/settings_store.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // 预设周期选项：(标签, 天数)
  static const _presets = [
    ('近7天', 7),
    ('近14天', 14),
    ('近1个月', 30),
    ('近6个月', 180),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListenableBuilder(
        listenable: settingsStore,
        builder: (context, _) {
          final days = settingsStore.readDays;
          final isPreset = _presets.any((p) => p.$2 == days);
          final customSelected = !isPreset;
          return ListView(
            children: [
              const _SectionHeader('读取周期'),
              ..._presets.map((p) => ListTile(
                    leading: Icon(
                      days == p.$2
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(p.$1),
                    onTap: () => settingsStore.setReadDays(p.$2),
                  )),
              ListTile(
                leading: Icon(
                  customSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('自定义'),
                subtitle: isPreset ? null : Text('当前：$days 天'),
                onTap: () => _showCustomDialog(context),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '仅读取该周期内的快递短信，降低读取与解析开销。',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showCustomDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('自定义读取周期'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '天数',
            suffixText: '天',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final n = int.tryParse(ctrl.text.trim());
              Navigator.pop(ctx, n);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result != null && result >= 1) {
      await settingsStore.setReadDays(result);
    } else if (result != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请输入大于 0 的天数')));
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
