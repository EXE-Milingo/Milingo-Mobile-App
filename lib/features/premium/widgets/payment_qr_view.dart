import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:milingo/core/network/milingo_models.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PaymentQrView extends StatelessWidget {
  const PaymentQrView({
    required this.order,
    required this.status,
    required this.isChecking,
    required this.qrBoundaryKey,
    required this.onClose,
    required this.onCopy,
    required this.onSaveQr,
    required this.onRetry,
    required this.onCreateNewOrder,
    this.errorMessage,
    super.key,
  });

  final CreatePayOSOrderResponse order;
  final String status;
  final bool isChecking;
  final GlobalKey qrBoundaryKey;
  final VoidCallback onClose;
  final ValueChanged<String> onCopy;
  final Future<void> Function() onSaveQr;
  final VoidCallback onRetry;
  final VoidCallback onCreateNewOrder;
  final String? errorMessage;

  bool get _isExpired => status == 'EXPIRED';
  bool get _isCancelled => status == 'CANCELLED';
  bool get _isPaid =>
      status == 'PAID' || status == 'SUCCESS' || status == 'COMPLETED';

  String get _amountLabel =>
      '${NumberFormat.decimalPattern('vi_VN').format(order.amount)}\u00A0₫';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
          color: const Color(0xFFE4502E),
          tooltip: 'Đóng',
        ),
        title: const Text(
          'Thanh toán bằng QR',
          style: TextStyle(
            color: Color(0xFF1C1B1B),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Quét mã bằng ứng dụng ngân hàng',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF1C1B1B),
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Giữ nguyên số tiền và nội dung chuyển khoản để hệ thống xác nhận tự động.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF765753),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  RepaintBoundary(
                    key: qrBoundaryKey,
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: QrImageView(
                        key: const Key('payos-qr-code'),
                        data: order.qrCode,
                        version: QrVersions.auto,
                        size: 250,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: onSaveQr,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Lưu mã QR'),
                  ),
                  const SizedBox(height: 24),
                  _TransferDetail(
                    label: 'Số tiền',
                    value: _amountLabel,
                    onCopy: () => onCopy(order.amount.toString()),
                  ),
                  _TransferDetail(
                    label: 'Tên tài khoản',
                    value: order.accountName,
                  ),
                  _TransferDetail(
                    label: 'Số tài khoản',
                    value: order.accountNumber,
                    copyKey: const Key('copy-account-number'),
                    onCopy: () => onCopy(order.accountNumber),
                  ),
                  _TransferDetail(
                    label: 'Nội dung chuyển khoản',
                    value: order.description,
                    onCopy: () => onCopy(order.description),
                  ),
                  const SizedBox(height: 20),
                  _StatusPanel(
                    isChecking: isChecking,
                    isPaid: _isPaid,
                    isExpired: _isExpired,
                    isCancelled: _isCancelled,
                    errorMessage: errorMessage,
                    onRetry: onRetry,
                    onCreateNewOrder: onCreateNewOrder,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TransferDetail extends StatelessWidget {
  const _TransferDetail({
    required this.label,
    required this.value,
    this.copyKey,
    this.onCopy,
  });

  final String label;
  final String value;
  final Key? copyKey;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E5E4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF78716C),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF1C1B1B),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              key: copyKey,
              onPressed: onCopy,
              tooltip: 'Sao chép',
              icon: const Icon(Icons.copy_rounded, size: 20),
              color: const Color(0xFFE4502E),
            ),
        ],
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.isChecking,
    required this.isPaid,
    required this.isExpired,
    required this.isCancelled,
    required this.errorMessage,
    required this.onRetry,
    required this.onCreateNewOrder,
  });

  final bool isChecking;
  final bool isPaid;
  final bool isExpired;
  final bool isCancelled;
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onCreateNewOrder;

  @override
  Widget build(BuildContext context) {
    if (isExpired || isCancelled) {
      return Column(
        children: [
          Text(
            isExpired ? 'Mã QR đã hết hạn' : 'Giao dịch đã bị hủy',
            style: const TextStyle(
              color: Color(0xFFB42318),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: onCreateNewOrder,
            child: const Text('Tạo mã QR mới'),
          ),
        ],
      );
    }

    if (isPaid) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32)),
          SizedBox(width: 8),
          Text(
            'Thanh toán thành công',
            style: TextStyle(
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    if (errorMessage != null) {
      return Column(
        children: [
          Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFB42318)),
          ),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isChecking) ...[
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
        ] else ...[
          const Icon(Icons.schedule_rounded, color: Color(0xFFE4502E)),
          const SizedBox(width: 8),
        ],
        const Flexible(
          child: Text(
            'Đang chờ ngân hàng xác nhận',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
