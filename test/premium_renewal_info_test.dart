import 'package:flutter_test/flutter_test.dart';
import 'package:milingo/features/premium/models/premium_renewal_info.dart';

void main() {
  final now = DateTime.utc(2026, 7, 16);

  test('free user keeps start action', () {
    const info = PremiumRenewalInfo.free();

    expect(
      info.actionLabel(planId: 'pro', durationDays: 30),
      'Bắt đầu ngay',
    );
  });

  test('same package renews while another package adds time', () {
    final info = PremiumRenewalInfo(
      isPremium: true,
      latestPlanId: 'pro',
      currentExpiresAt: DateTime.utc(2026, 7, 28),
    );

    expect(
      info.actionLabel(planId: 'pro', durationDays: 30),
      'Gia hạn thêm 30 ngày',
    );
    expect(
      info.actionLabel(planId: 'ultra', durationDays: 365),
      'Mua thêm 365 ngày',
    );
  });

  test('estimated expiry preserves remaining time', () {
    final info = PremiumRenewalInfo(
      isPremium: true,
      latestPlanId: 'pro',
      currentExpiresAt: DateTime.utc(2026, 7, 28),
    );

    expect(
      info.estimatedExpiry(now: now, durationDays: 30),
      DateTime.utc(2026, 8, 27),
    );
  });

  test('latest package is preferred only while available', () {
    const info = PremiumRenewalInfo(
      isPremium: true,
      latestPlanId: 'ultra',
      currentExpiresAt: null,
    );

    expect(info.preferredPlanId({'plus', 'pro', 'ultra'}, 'pro'), 'ultra');
    expect(info.preferredPlanId({'plus', 'pro'}, 'pro'), 'pro');
  });

  test('missing subscription falls back without blocking checkout', () {
    expect(PremiumRenewalInfo.fromOverview(null).isPremium, isFalse);
  });

  test('active checkout notice explains additive time', () {
    final info = PremiumRenewalInfo(
      isPremium: true,
      latestPlanId: 'pro',
      currentExpiresAt: DateTime.utc(2026, 7, 28),
    );

    expect(
      info.checkoutNotice(now: now, durationDays: 30),
      contains('Thời gian còn lại được giữ nguyên'),
    );
    expect(
      info.checkoutNotice(now: now, durationDays: 30),
      contains('30 ngày'),
    );
  });
}
