import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_date_formatter.dart';
import '../../../core/network/app_api_client.dart';
import '../../shared/application/api_client_provider.dart';
import '../domain/today_dashboard.dart';

abstract class TodayDashboardRepository {
  Future<TodayDashboardData> fetchDay(DateTime date);
}

class ApiTodayDashboardRepository implements TodayDashboardRepository {
  const ApiTodayDashboardRepository({required this.apiClient});

  final AppApiClient apiClient;

  @override
  Future<TodayDashboardData> fetchDay(DateTime date) async {
    final payload = await apiClient.getMap(
      '/meals',
      queryParameters: {'date': formatApiDate(date)},
    );
    return TodayDashboardData.fromJson(payload);
  }
}

final todayDashboardRepositoryProvider = Provider<TodayDashboardRepository>((ref) {
  final apiClient = ref.watch(appApiClientProvider);
  return ApiTodayDashboardRepository(apiClient: apiClient);
});
