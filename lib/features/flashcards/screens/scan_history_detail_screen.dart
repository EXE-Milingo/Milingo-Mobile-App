import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/network/milingo_models.dart';
import 'package:milingo/features/flashcards/widgets/scan_history_widgets.dart';

class ScanHistoryDetailScreen extends StatelessWidget {
  const ScanHistoryDetailScreen({required this.item, super.key});

  final SnapHistoryItemResponse item;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: ScanHistoryColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _DetailHeader(onBack: () => context.pop()),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
                  child: Column(
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              ScanHistoryColors.orangeLight,
                              ScanHistoryColors.orangeDeep,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: ScanHistoryColors.orange.withValues(
                                alpha: 0.28,
                              ),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        item.keyword,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: ScanHistoryColors.ink,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (item.pronunciation.trim().isNotEmpty) ...[
                        const SizedBox(height: 7),
                        Text(
                          item.pronunciation,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: ScanHistoryColors.muted,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      _DetailSection(
                        title: 'Nghĩa',
                        child: Text(
                          item.translation.trim().isEmpty
                              ? 'Chưa có bản dịch'
                              : item.translation,
                          style: const TextStyle(
                            color: ScanHistoryColors.ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            height: 1.45,
                          ),
                        ),
                      ),
                      if (item.exampleSentence.trim().isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _DetailSection(
                          title: 'Ví dụ',
                          child: Text(
                            item.exampleSentence,
                            style: const TextStyle(
                              color: ScanHistoryColors.ink,
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                      if (item.relatedWords.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _DetailSection(
                          title: 'Từ liên quan',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: item.relatedWords.map((word) {
                              final translation = word.translation.trim();
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: ScanHistoryColors.orange.withValues(
                                    alpha: 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  translation.isEmpty
                                      ? word.keyword
                                      : '${word.keyword} · $translation',
                                  style: const TextStyle(
                                    color: ScanHistoryColors.orangeDeep,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      _DetailSection(
                        title: 'Thời gian quét',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              color: ScanHistoryColors.orange,
                              size: 19,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatLocalDateTime(item.createdAt),
                              style: const TextStyle(
                                color: ScanHistoryColors.ink,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLocalDateTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$hour:$minute · $day/$month/${local.year}';
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 20,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 4,
              child: IconButton(
                onPressed: onBack,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: ScanHistoryColors.ink,
                  size: 19,
                ),
              ),
            ),
          ),
          const Text(
            'Chi tiết từ',
            style: TextStyle(
              color: ScanHistoryColors.ink,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: ScanHistoryColors.orange,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
