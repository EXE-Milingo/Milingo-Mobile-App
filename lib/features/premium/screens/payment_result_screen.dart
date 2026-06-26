import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/network/milingo_api_service.dart';
import 'package:milingo/core/theme/app_theme.dart';

const _resultInk = Color(0xFF17201B);
const _resultMuted = Color(0xFF66736C);
const _resultPaper = Color(0xFFF7FAF5);
const _resultMint = Color(0xFF0B7A75);
const _resultLine = Color(0xFFE1E7DF);

class PaymentResultScreen extends ConsumerStatefulWidget {
  const PaymentResultScreen({
    required this.isSuccess,
    this.orderCode,
    super.key,
  });

  final bool isSuccess;
  final int? orderCode;

  @override
  ConsumerState<PaymentResultScreen> createState() =>
      _PaymentResultScreenState();
}

class _PaymentResultScreenState extends ConsumerState<PaymentResultScreen> {
  bool _isChecking = false;
  PremiumStatusResponse? _status;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.isSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkStatus());
    }
  }

  Future<void> _checkStatus() async {
    setState(() {
      _isChecking = true;
      _error = null;
    });

    try {
      final api = ref.read(milingoApiServiceProvider);
      
      final orderCode = widget.orderCode;
      if (orderCode != null) {
        try {
          await api.verifyPayOSOrder(orderCode);
        } catch (e) {
          debugPrint('Verification error during status sync: $e');
        }
      }

      final status = await api.getPremiumStatus();
      if (!mounted) return;
      setState(() => _status = status);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is MilingoApiException
            ? e.message
            : 'Chưa thể kiểm tra trạng thái Premium.';
      });
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final activated = _status?.isPremium == true;
    final color = widget.isSuccess ? _resultMint : AppTheme.primaryColor;
    final icon = widget.isSuccess ? Icons.verified_rounded : Icons.undo_rounded;
    final title = widget.isSuccess
        ? activated
            ? 'Premium đã kích hoạt'
            : 'Thanh toán đang xác nhận'
        : 'Thanh toán đã hủy';
    final message = widget.isSuccess
        ? activated
            ? _expiryMessage(_status!.expiresAt)
            : 'PayOS đã nhận giao dịch. Nếu trạng thái chưa đổi, kiểm tra lại sau vài phút.'
        : 'Không có khoản phí nào được ghi nhận. Bạn có thể chọn lại gói bất cứ lúc nào.';

    return Scaffold(
      backgroundColor: _resultPaper,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding + 20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Đóng',
                  onPressed: () => context.go(AppConstants.premiumRoute),
                  icon: const Icon(Icons.close_rounded),
                  color: _resultInk,
                ),
              ),
              const Spacer(),
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(46),
                  border: Border.all(color: color.withValues(alpha: 0.28)),
                ),
                child: Icon(icon, color: color, size: 44),
              ),
              const SizedBox(height: 28),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _resultInk,
                  fontSize: 30,
                  height: 1.04,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _resultMuted,
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _resultLine),
                  ),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.errorColor,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (widget.isSuccess && !activated)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: _isChecking ? null : _checkStatus,
                    icon: _isChecking
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_rounded),
                    label: Text(_isChecking ? 'Đang kiểm tra' : 'Kiểm tra lại'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _resultMint,
                      side: const BorderSide(color: _resultMint),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              if (widget.isSuccess && !activated) const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => context.go(
                    activated
                        ? AppConstants.homeRoute
                        : AppConstants.premiumRoute,
                  ),
                  icon: Icon(
                    activated
                        ? Icons.home_rounded
                        : Icons.workspace_premium_rounded,
                  ),
                  label: Text(activated ? 'Về trang chủ' : 'Về trang Premium'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _expiryMessage(DateTime? expiresAt) {
    if (expiresAt == null) {
      return 'Tài khoản của bạn đang có Premium.';
    }

    final formatted = DateFormat('dd/MM/yyyy').format(expiresAt.toLocal());
    return 'Tài khoản Premium có hiệu lực đến $formatted.';
  }
}
