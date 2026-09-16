// 快递卡片：列表页和查询页共用。
//
// 双触点交互：
// - 触点 A（卡片主体）：点击展开/折叠，展开显示完整字段。
// - 触点 B（右上角状态标签）：点击切换已取/未取（InkWell 默认 opaque 阻断冒泡）。
// 题头去重：station 空 / 等于 company / 以"company("开头时只显示 company，
//           避免"韵达快递·韵达快递""多多代收点·多多代收点"重复。

import 'package:flutter/material.dart';

import '../models/express_info.dart';

class ExpressCard extends StatefulWidget {
  final ExpressInfo express;
  final VoidCallback? onStatusToggle; // 右上角标签点击：切换已取/未取

  const ExpressCard({super.key, required this.express, this.onStatusToggle});

  @override
  State<ExpressCard> createState() => _ExpressCardState();
}

class _ExpressCardState extends State<ExpressCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.express;
    final picked = e.isPicked;
    final theme = Theme.of(context);

    // 已取：题头置灰 + 删除线
    final titleStyle = picked
        ? TextStyle(
            color: theme.colorScheme.outline,
            decoration: TextDecoration.lineThrough,
          )
        : TextStyle(color: theme.colorScheme.onSurface);
    final bodyStyle = TextStyle(
      color: picked
          ? theme.colorScheme.outline
          : theme.colorScheme.onSurfaceVariant,
      fontSize: 13,
    );

    return Card(
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded), // 触点 A：展开/折叠
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    picked ? Icons.check_circle : Icons.inventory_2_outlined,
                    size: 28,
                    color: picked
                        ? theme.colorScheme.outline
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _buildTitle(e),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '取件码：${e.pickUpCode}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: bodyStyle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 触点 B：状态标签。InkWell 默认 opaque，阻断冒泡，点它不触发展开。
                  InkWell(
                    onTap: widget.onStatusToggle,
                    borderRadius: BorderRadius.circular(12),
                    child: _StatusChip(picked: picked),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _expanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(height: 16),
                          _detailRow('公司', e.company, bodyStyle),
                          _detailRow('地点', e.station.isEmpty ? '未识别' : e.station, bodyStyle),
                          _detailRow('取件码', e.pickUpCode, bodyStyle),
                          if (e.phone.isNotEmpty)
                            _detailRow('号码', e.phone, bodyStyle),
                          _detailRow('送达时间',
                              _fmtTime(e.smsDate ?? e.createdAt ?? e.updatedAt), bodyStyle),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 题头去重：station 空或等于 company 时只显示 company
  String _buildTitle(ExpressInfo e) {
    if (e.station.isEmpty || e.station == e.company) {
      return e.company;
    }
    return '${e.company} · ${e.station}';
  }

  Widget _detailRow(String label, String value, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(
              text: '$label：',
              style: style.copyWith(fontWeight: FontWeight.bold)),
          TextSpan(text: value, style: style),
        ]),
      ),
    );
  }

  String _fmtTime(DateTime t) {
    final m = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$m-$d $hh:$mm';
  }
}

class _StatusChip extends StatelessWidget {
  final bool picked;
  const _StatusChip({required this.picked});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: picked
            ? Theme.of(context).colorScheme.outlineVariant
            : Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        picked ? '已取' : '未取',
        style: TextStyle(
          fontSize: 12,
          color: picked
              ? Theme.of(context).colorScheme.outline
              : Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
