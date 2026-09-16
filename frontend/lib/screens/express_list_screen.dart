// "我的快递"页（DAY5 本地化版）。
//
// 打开应用 → 申请短信权限 → 读收件箱（按读取周期时间戳下沉过滤）→ 解析入库（去重）→ 展示卡片。
// 数据全本地，不依赖后端。受 AppConfig.enableLocalSms 开关控制。
// 读取周期由 settingsStore 控制，变化时自动重读。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_config.dart';
import '../models/express_info.dart';
import '../parsers/sms_parser.dart';
import '../services/express_store.dart';
import '../services/settings_store.dart';
import '../services/sms_service.dart';
import '../widgets/express_card.dart';

class ExpressListScreen extends StatefulWidget {
  const ExpressListScreen({super.key});

  @override
  State<ExpressListScreen> createState() => _ExpressListScreenState();
}

class _ExpressListScreenState extends State<ExpressListScreen> {
  final _sms = SmsService.instance;
  final _store = ExpressStore.instance;
  List<ExpressInfo> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    settingsStore.addListener(_onSettingsChange);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    settingsStore.removeListener(_onSettingsChange);
    super.dispose();
  }

  // 读取周期变化时重读
  void _onSettingsChange() {
    if (mounted) _load();
  }

  int _loadSeq = 0; // 防抖序号，只接受最新一次 _load 的结果

  Future<void> _load() async {
    if (!AppConfig.enableLocalSms) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final seq = ++_loadSeq;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (!mounted) return;
      // 权限触发：未授权先弹解释窗，不同意则退出应用（必要权限）
      final granted = await _sms.ensurePermission(context);
      if (seq != _loadSeq) return;
      if (!granted) {
        SystemNavigator.pop();
        return;
      }
      // 读取周期：近 N 天（默认14），算出时间戳下界
      final sinceMs = DateTime.now().millisecondsSinceEpoch -
          settingsStore.readDays * 24 * 60 * 60 * 1000;
      final messages = await _sms.readInbox(sinceMs: sinceMs);
      if (seq != _loadSeq) return;
      // 解析 + 入库去重（按短信 _id）
      final items = messages
          .where((m) => m.id != null)
          .map((m) => (
                smsId: m.id!,
                smsDate: m.date,
                parsed: parseSms(m.body ?? ''),
              ))
          .toList();
      await _store.upsertAll(items);
      if (seq != _loadSeq) return;
      _items = await _store.queryAll(sinceMs);
    } catch (e) {
      if (seq != _loadSeq) return;
      _error = e.toString();
    } finally {
      if (seq == _loadSeq) {
        _loading = false;
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> _toggle(ExpressInfo e) async {
    final newStatus = e.isPicked ? 0 : 1;
    try {
      await _store.updateStatus(e.id, newStatus);
      if (!mounted) return;
      // 本地切换状态（划线/取消划线），不立即重拉
      setState(() {
        _items = _items
            .map((x) => x.id == e.id ? x.copyWith(status: newStatus) : x)
            .toList();
      });
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('操作失败：$err')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的快递'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text('加载失败：$_error', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _load, child: const Text('重试')),
          ],
        ),
      );
    }
    if (!AppConfig.enableLocalSms) {
      return const Center(
        child: Text('短信功能未启用', style: TextStyle(color: Colors.grey)),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Text('暂无未取件快递', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final e = _items[index];
        return ExpressCard(express: e, onStatusToggle: () => _toggle(e));
      },
    );
  }
}
