import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milingo/core/network/milingo_api_service.dart';
import 'package:milingo/features/auth/providers/auth_provider.dart';
import 'package:milingo/features/premium/providers/subscription_provider.dart';
import 'package:milingo/features/profile/providers/profile_provider.dart';

abstract interface class PaymentGateway {
  Future<CreatePayOSOrderResponse?> getPendingOrder();

  Future<PayOSOrderStatusResponse> verifyOrder(int orderCode);

  Future<PremiumStatusResponse> getPremiumStatus();
}

class ApiPaymentGateway implements PaymentGateway {
  const ApiPaymentGateway(this._api);

  final MilingoApiService _api;

  @override
  Future<CreatePayOSOrderResponse?> getPendingOrder() {
    return _api.getPendingPayOSOrder();
  }

  @override
  Future<PremiumStatusResponse> getPremiumStatus() {
    return _api.getPremiumStatus();
  }

  @override
  Future<PayOSOrderStatusResponse> verifyOrder(int orderCode) {
    return _api.verifyPayOSOrder(orderCode);
  }
}

final paymentGatewayProvider = Provider<PaymentGateway>((ref) {
  return ApiPaymentGateway(ref.watch(milingoApiServiceProvider));
});

final paymentPollIntervalProvider = Provider<Duration>((ref) {
  return const Duration(seconds: 5);
});

final paymentUserIdProvider = Provider<String?>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  return authUser?.uid ?? FirebaseAuth.instance.currentUser?.uid;
});

final paymentEntitlementRefreshProvider =
    Provider<Future<void> Function()>((ref) {
  return () async {
    await ref.read(userProfileProvider.notifier).refresh();
    ref.invalidate(subscriptionOverviewProvider);
  };
});

class PaymentQrState {
  const PaymentQrState({
    required this.order,
    required this.status,
    this.isChecking = false,
    this.errorMessage,
  });

  final CreatePayOSOrderResponse order;
  final String status;
  final bool isChecking;
  final String? errorMessage;

  bool get isPaid =>
      status == 'PAID' || status == 'SUCCESS' || status == 'COMPLETED';

  bool get isTerminal => isPaid || status == 'CANCELLED' || status == 'EXPIRED';

  PaymentQrState copyWith({
    String? status,
    bool? isChecking,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PaymentQrState(
      order: order,
      status: status ?? this.status,
      isChecking: isChecking ?? this.isChecking,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class PaymentQrNotifier extends AutoDisposeFamilyNotifier<PaymentQrState,
    CreatePayOSOrderResponse> {
  Timer? _timer;
  bool _isChecking = false;
  bool _didRefreshEntitlement = false;

  @override
  PaymentQrState build(CreatePayOSOrderResponse order) {
    ref.onDispose(_cancelTimer);
    final initial = PaymentQrState(order: order, status: order.status);
    if (!initial.isTerminal) {
      _startTimer();
      Future<void>.microtask(checkNow);
    }
    return initial;
  }

  Future<void> checkNow() async {
    if (_isChecking || state.isTerminal) return;
    _isChecking = true;
    state = state.copyWith(isChecking: true, clearError: true);
    try {
      final result = await ref
          .read(paymentGatewayProvider)
          .verifyOrder(state.order.orderCode);
      state = state.copyWith(
        status: result.status,
        isChecking: false,
        clearError: true,
      );
      if (state.isTerminal) {
        _cancelTimer();
      }
      if (result.isPaid && !_didRefreshEntitlement) {
        _didRefreshEntitlement = true;
        await ref.read(paymentEntitlementRefreshProvider)();
      }
    } catch (error) {
      state = state.copyWith(
        isChecking: false,
        errorMessage: error is MilingoApiException
            ? error.message
            : 'Chưa thể kiểm tra thanh toán. Vui lòng thử lại.',
      );
    } finally {
      _isChecking = false;
    }
  }

  void pause() => _cancelTimer();

  void resume() {
    if (state.isTerminal) return;
    _startTimer();
    unawaited(checkNow());
  }

  void _startTimer() {
    _cancelTimer();
    _timer = Timer.periodic(
      ref.read(paymentPollIntervalProvider),
      (_) => unawaited(checkNow()),
    );
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }
}

final paymentQrProvider = AutoDisposeNotifierProviderFamily<PaymentQrNotifier,
    PaymentQrState, CreatePayOSOrderResponse>(PaymentQrNotifier.new);

class PaymentReconciliationNotifier
    extends Notifier<AsyncValue<CreatePayOSOrderResponse?>> {
  bool _isReconciling = false;

  @override
  AsyncValue<CreatePayOSOrderResponse?> build() {
    final uid = ref.watch(paymentUserIdProvider);
    if (uid == null) return const AsyncData(null);
    Future<void>.microtask(reconcileNow);
    return const AsyncLoading();
  }

  Future<void> reconcileNow() async {
    if (_isReconciling || ref.read(paymentUserIdProvider) == null) return;
    _isReconciling = true;
    state = const AsyncLoading();
    try {
      final gateway = ref.read(paymentGatewayProvider);
      final pendingOrder = await gateway.getPendingOrder();
      final premiumStatus = await gateway.getPremiumStatus();
      if (premiumStatus.isPremium) {
        await ref.read(paymentEntitlementRefreshProvider)();
      }
      state = AsyncData(pendingOrder);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    } finally {
      _isReconciling = false;
    }
  }

  Future<void> handleAppResumed() => reconcileNow();
}

final paymentReconciliationProvider = NotifierProvider<
    PaymentReconciliationNotifier,
    AsyncValue<CreatePayOSOrderResponse?>>(PaymentReconciliationNotifier.new);
