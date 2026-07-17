import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/features/flashcards/providers/scan_history_provider.dart';
import 'package:milingo/features/flashcards/widgets/scan_history_widgets.dart';

class ScanHistoryScreen extends ConsumerStatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  ConsumerState<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends ConsumerState<ScanHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreNearEnd);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadMoreNearEnd)
      ..dispose();
    super.dispose();
  }

  void _loadMoreNearEnd() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.userScrollDirection == ScrollDirection.reverse &&
        position.extentAfter <= 200) {
      unawaited(ref.read(scanHistoryProvider.notifier).loadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(scanHistoryProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: ScanHistoryColors.background,
        body: SafeArea(
          child: Column(
            children: [
              const _HistoryHeader(),
              Expanded(
                child: history.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: ScanHistoryColors.orange,
                    ),
                  ),
                  error: (error, _) => _InitialError(
                    onRetry: () => ref.invalidate(scanHistoryProvider),
                  ),
                  data: (state) {
                    if (state.items.isEmpty) {
                      return const _EmptyHistory();
                    }

                    return CustomScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        const SliverPadding(
                          padding: EdgeInsets.fromLTRB(24, 10, 24, 15),
                          sliver: SliverToBoxAdapter(
                            child: Text(
                              'Dòng thời gian',
                              style: TextStyle(
                                color: ScanHistoryColors.ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        ScanHistoryTimeline(
                          items: state.items,
                          onItemTap: (item) => context.push(
                            AppConstants.scanHistoryDetailRoute,
                            extra: item,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: _HistoryFooter(
                            state: state,
                            onRetry: () => unawaited(
                              ref.read(scanHistoryProvider.notifier).loadMore(),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 108,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 20,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 5,
              shadowColor: Colors.black.withValues(alpha: 0.16),
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: ScanHistoryColors.ink,
                  size: 19,
                ),
              ),
            ),
          ),
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Lịch sử quét',
                style: TextStyle(
                  color: ScanHistoryColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Theo dõi hành trình học tập của bạn',
                style: TextStyle(
                  color: ScanHistoryColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryFooter extends StatelessWidget {
  const _HistoryFooter({required this.state, required this.onRetry});

  final ScanHistoryState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 2, 16, 28),
        child: Center(
          child: SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: ScanHistoryColors.orange,
            ),
          ),
        ),
      );
    }

    if (state.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          children: [
            Text(
              state.loadMoreError!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ScanHistoryColors.muted,
                fontSize: 12,
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (!state.hasMore) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Text(
          'Bạn đã xem hết lịch sử quét',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ScanHistoryColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return const SizedBox(height: 24);
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: ScanHistoryColors.orange,
              size: 46,
            ),
            SizedBox(height: 14),
            Text(
              'Chưa có từ nào được quét',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ScanHistoryColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Các từ bạn quét sẽ xuất hiện tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(color: ScanHistoryColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _InitialError extends StatelessWidget {
  const _InitialError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: ScanHistoryColors.orange,
              size: 42,
            ),
            const SizedBox(height: 12),
            const Text(
              'Không thể tải lịch sử quét',
              style: TextStyle(
                color: ScanHistoryColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: ScanHistoryColors.orange,
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
