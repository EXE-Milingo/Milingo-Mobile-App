import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:milingo/core/network/milingo_api_service.dart';
import 'package:milingo/core/theme/app_theme.dart';

const _historyBg = Color(0xFFFFF7F3);
const _historySurface = Colors.white;
const _historyInk = Color(0xFF211A16);
const _historyMuted = Color(0xFF7B6D66);
const _historyLine = Color(0xFFF0DFD8);
const _historyOrange = AppTheme.primaryColor;
const _historySoft = Color(0xFFFFECE6);
const _successGreen = Color(0xFF18A566);
const _warning = Color(0xFFF5A000);
const _danger = Color(0xFFE85A4F);

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  PaymentTransactionHistoryResponse? _history;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistory());
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final history = await ref
          .read(milingoApiServiceProvider)
          .getPaymentTransactionHistory();
      if (!mounted) return;
      setState(() => _history = history);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is MilingoApiException
            ? e.message
            : 'Chưa thể tải lịch sử giao dịch.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = _history;
    final transactions = history?.transactions ?? const [];
    final grouped = _groupTransactions(transactions);

    return Scaffold(
      backgroundColor: _historyBg,
      body: SafeArea(
        child: RefreshIndicator(
          color: _historyOrange,
          onRefresh: _loadHistory,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              _HistoryHeader(onBack: () => context.pop()),
              const SizedBox(height: 18),
              _YearSummaryCard(
                totalSpentThisYear: history?.totalSpentThisYear ?? 0,
                transactionCount: transactions.length,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                _ErrorPanel(message: _error!, onRetry: _loadHistory),
              ],
              const SizedBox(height: 28),
              if (_isLoading && history == null)
                const _LoadingPanel()
              else if (transactions.isEmpty)
                const _EmptyHistory()
              else ...[
                for (final entry in grouped.entries) ...[
                  _MonthLabel(entry.key),
                  const SizedBox(height: 12),
                  for (var i = 0; i < entry.value.length; i++) ...[
                    _TransactionTile(transaction: entry.value[i]),
                    if (i != entry.value.length - 1) const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 28),
                ],
                const _PromoCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Quay lại',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: _historyOrange,
          ),
          const Expanded(
            child: Text(
              'Lịch sử giao dịch',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _historyInk,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _YearSummaryCard extends StatelessWidget {
  const _YearSummaryCard({
    required this.totalSpentThisYear,
    required this.transactionCount,
  });

  final int totalSpentThisYear;
  final int transactionCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _historySurface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: _historyOrange.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TỔNG CHI TIÊU NĂM NAY',
            style: TextStyle(
              color: _historyMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatMoney(totalSpentThisYear),
            style: const TextStyle(
              color: _historyInk,
              fontSize: 30,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                text: totalSpentThisYear > 0 ? 'Premium user' : 'Free user',
                active: totalSpentThisYear > 0,
              ),
              _FilterChip(
                text: '$transactionCount giao dịch',
                active: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.text,
    required this.active,
  });

  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? _historySoft : const Color(0xFFF5F0ED),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: active ? _historyOrange : _historyMuted,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MonthLabel extends StatelessWidget {
  const _MonthLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: _historyMuted,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Expanded(
          child: Divider(
            height: 1,
            indent: 12,
            color: _historyLine,
          ),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final PaymentTransactionResponse transaction;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(transaction);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _historySurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _historySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_transactionIcon(transaction),
                color: _historyOrange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.planName.isEmpty
                      ? 'Gói Premium'
                      : transaction.planName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _historyInk,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _transactionDetail(transaction),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _historyMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatMoney(transaction.amount),
                style: const TextStyle(
                  color: _historyInk,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _statusLabel(transaction).toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 34),
        child: CircularProgressIndicator(color: _historyOrange),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _historySurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: _danger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _historyInk,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Thử lại',
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            color: _historyOrange,
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _historySurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_rounded, color: _historyOrange, size: 28),
          SizedBox(height: 10),
          Text(
            'Chưa có giao dịch',
            style: TextStyle(
              color: _historyInk,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Các đơn PayOS thành công, đang chờ hoặc đã hủy sẽ xuất hiện tại đây.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _historyMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Image.asset(
            'assets/images/dog_beach.png',
            height: 132,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.48),
                    Colors.black.withValues(alpha: 0.08),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            left: 18,
            bottom: 18,
            right: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ƯU ĐÃI HỌC TẬP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Nâng cấp kỹ năng cùng Milingo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Map<String, List<PaymentTransactionResponse>> _groupTransactions(
  List<PaymentTransactionResponse> transactions,
) {
  final grouped = <String, List<PaymentTransactionResponse>>{};
  for (final transaction in transactions) {
    final key = _monthLabel(transaction.displayDate);
    grouped.putIfAbsent(key, () => []).add(transaction);
  }
  return grouped;
}

String _monthLabel(DateTime? date) {
  if (date == null) return 'Chưa rõ thời gian';
  final local = date.toLocal();
  return 'Tháng ${local.month}, ${local.year}';
}

String _transactionDetail(PaymentTransactionResponse transaction) {
  final method = transaction.paymentMethodLabel.isEmpty
      ? 'Thanh toán'
      : transaction.paymentMethodLabel;
  final date = transaction.displayDate;
  if (date == null) return method;
  return '$method  ·  ${DateFormat('HH:mm, dd/MM').format(date.toLocal())}';
}

String _formatMoney(int amount) {
  return '${NumberFormat.decimalPattern('vi_VN').format(amount)}đ';
}

String _statusLabel(PaymentTransactionResponse transaction) {
  if (transaction.statusLabel.isNotEmpty) return transaction.statusLabel;
  return transaction.isPaid ? 'Thành công' : 'Đang xử lý';
}

Color _statusColor(PaymentTransactionResponse transaction) {
  final status = transaction.status.toUpperCase();
  if (transaction.isPaid) return _successGreen;
  if (status.contains('CANCEL') || status.contains('EXPIRED')) return _warning;
  if (status.contains('FAIL')) return _danger;
  return _historyMuted;
}

IconData _transactionIcon(PaymentTransactionResponse transaction) {
  if (transaction.source == 'google_play') return Icons.android_rounded;
  if (transaction.isPaid) return Icons.workspace_premium_rounded;
  return Icons.credit_card_rounded;
}
