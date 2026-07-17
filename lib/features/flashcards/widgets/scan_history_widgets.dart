import 'package:flutter/material.dart';
import 'package:milingo/core/network/milingo_models.dart';

class ScanHistoryColors {
  const ScanHistoryColors._();

  static const background = Color(0xFFFBF7F2);
  static const orange = Color(0xFFFF6A00);
  static const orangeLight = Color(0xFFFF8A1F);
  static const orangeDeep = Color(0xFFFF4D1A);
  static const ink = Color(0xFF1D1814);
  static const muted = Color(0x8C1D1814);
}

class ScanHistoryTimeline extends StatelessWidget {
  const ScanHistoryTimeline({
    required this.items,
    required this.onItemTap,
    super.key,
  });

  final List<SnapHistoryItemResponse> items;
  final ValueChanged<SnapHistoryItemResponse> onItemTap;

  @override
  Widget build(BuildContext context) {
    final groups = <DateTime, List<SnapHistoryItemResponse>>{};
    for (final item in items) {
      final local = item.createdAt.toLocal();
      final date = DateTime(local.year, local.month, local.day);
      groups.putIfAbsent(date, () => []).add(item);
    }

    final entries = groups.entries.toList(growable: false);
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final group = entries[index];
            return _HistoryDateGroup(
              label: _dateLabel(group.key),
              items: group.value,
              onItemTap: onItemTap,
            );
          },
          childCount: entries.length,
        ),
      ),
    );
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final difference = today.difference(date).inDays;
    if (difference == 0) return 'Hôm nay';
    if (difference == 1) return 'Hôm qua';
    return '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class _HistoryDateGroup extends StatelessWidget {
  const _HistoryDateGroup({
    required this.label,
    required this.items,
    required this.onItemTap,
  });

  final String label;
  final List<SnapHistoryItemResponse> items;
  final ValueChanged<SnapHistoryItemResponse> onItemTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 9),
            child: Text(
              label,
              style: const TextStyle(
                color: ScanHistoryColors.orange,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ...items.map(
            (item) => _TimelineItem(
              item: item,
              onTap: () => onItemTap(item),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.item, required this.onTap});

  final SnapHistoryItemResponse item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 16,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned.fill(
                  left: 7,
                  right: 7,
                  child: ColoredBox(
                    color: ScanHistoryColors.orange.withValues(alpha: 0.25),
                  ),
                ),
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 30),
                  decoration: const BoxDecoration(
                    color: ScanHistoryColors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                shadowColor: Colors.black.withValues(alpha: 0.16),
                elevation: 8,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(22),
                  child: Padding(
                    padding: const EdgeInsets.all(13),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: ScanHistoryColors.orange.withValues(
                              alpha: 0.10,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: ScanHistoryColors.orange,
                            size: 25,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.keyword,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: ScanHistoryColors.ink,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              if (item.translation.trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  item.translation,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: ScanHistoryColors.orange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                              if (item.pronunciation.trim().isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  item.pronunciation,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: ScanHistoryColors.muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: ScanHistoryColors.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
