import 'package:intl/intl.dart';
import 'package:milingo/core/network/milingo_models.dart';

class PremiumRenewalInfo {
  const PremiumRenewalInfo({
    required this.isPremium,
    required this.latestPlanId,
    required this.currentExpiresAt,
  });

  const PremiumRenewalInfo.free()
      : isPremium = false,
        latestPlanId = null,
        currentExpiresAt = null;

  factory PremiumRenewalInfo.fromOverview(
    SubscriptionOverviewResponse? overview,
  ) {
    if (overview == null || !overview.isPremium) {
      return const PremiumRenewalInfo.free();
    }

    return PremiumRenewalInfo(
      isPremium: true,
      latestPlanId: overview.planId,
      currentExpiresAt: overview.expiresAt,
    );
  }

  final bool isPremium;
  final String? latestPlanId;
  final DateTime? currentExpiresAt;

  String preferredPlanId(Set<String> availableIds, String fallbackId) {
    final latest = latestPlanId;
    return latest != null && availableIds.contains(latest)
        ? latest
        : fallbackId;
  }

  String actionLabel({required String planId, required int durationDays}) {
    if (!isPremium) return 'Bắt đầu ngay';
    final prefix = planId == latestPlanId ? 'Gia hạn thêm' : 'Mua thêm';
    return '$prefix $durationDays ngày';
  }

  DateTime estimatedExpiry({required DateTime now, required int durationDays}) {
    final nowUtc = now.toUtc();
    final expiryUtc = currentExpiresAt?.toUtc();
    final baseDate =
        expiryUtc != null && expiryUtc.isAfter(nowUtc) ? expiryUtc : nowUtc;
    return baseDate.add(Duration(days: durationDays));
  }

  String checkoutNotice({
    required int durationDays,
    required DateTime now,
  }) {
    if (!isPremium) {
      return 'Gói này kích hoạt $durationDays ngày Premium.';
    }

    final estimatedDate = DateFormat('dd/MM/yyyy').format(
      estimatedExpiry(now: now, durationDays: durationDays).toLocal(),
    );
    return 'Thời gian còn lại được giữ nguyên. '
        'Giao dịch cộng thêm $durationDays ngày, dự kiến đến $estimatedDate.';
  }
}
