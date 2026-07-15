import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/network/milingo_models.dart';
import 'package:milingo/features/premium/providers/payment_provider.dart';
import 'package:milingo/features/premium/widgets/payment_qr_view.dart';

class PaymentQrScreen extends ConsumerStatefulWidget {
  const PaymentQrScreen({required this.order, super.key});

  final CreatePayOSOrderResponse order;

  @override
  ConsumerState<PaymentQrScreen> createState() => _PaymentQrScreenState();
}

class _PaymentQrScreenState extends ConsumerState<PaymentQrScreen>
    with WidgetsBindingObserver {
  final _qrBoundaryKey = GlobalKey();
  bool _didNavigateToResult = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(paymentQrProvider(widget.order).notifier);
    if (state == AppLifecycleState.resumed) {
      notifier.resume();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      notifier.pause();
    }
  }

  Future<void> _saveQr() async {
    try {
      final boundary = _qrBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('QR is not ready');
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('Could not encode QR');
      await Gal.putImageBytes(
        bytes.buffer.asUint8List(),
        album: 'MiLingo',
      );
      _showMessage('Đã lưu mã QR vào thư viện ảnh.');
    } catch (_) {
      _showMessage(
          'Không thể lưu mã QR. Vui lòng kiểm tra quyền truy cập ảnh.');
    }
  }

  void _copy(String value) {
    unawaited(Clipboard.setData(ClipboardData(text: value)));
    _showMessage('Đã sao chép.');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _openSuccessResult() {
    if (_didNavigateToResult || !mounted) return;
    _didNavigateToResult = true;
    context.go(
      '${AppConstants.paymentSuccessRoute}?orderCode=${widget.order.orderCode}',
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(paymentQrProvider(widget.order), (previous, next) {
      if (next.isPaid && previous?.isPaid != true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openSuccessResult();
        });
      }
    });
    final state = ref.watch(paymentQrProvider(widget.order));

    return PaymentQrView(
      order: widget.order,
      status: state.status,
      isChecking: state.isChecking,
      errorMessage: state.errorMessage,
      qrBoundaryKey: _qrBoundaryKey,
      onClose: () => context.pop(),
      onCopy: _copy,
      onSaveQr: _saveQr,
      onRetry: () {
        unawaited(
          ref.read(paymentQrProvider(widget.order).notifier).checkNow(),
        );
      },
      onCreateNewOrder: () => context.pop(true),
    );
  }
}
