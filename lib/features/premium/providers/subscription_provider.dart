import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milingo/core/network/milingo_api_service.dart';

final subscriptionOverviewProvider =
    FutureProvider.autoDispose<SubscriptionOverviewResponse>((ref) async {
  return ref.watch(milingoApiServiceProvider).getSubscriptionOverview();
});
