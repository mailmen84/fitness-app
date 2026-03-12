import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_date_formatter.dart';
import '../../../core/network/app_api_client.dart';
import '../../shared/application/api_client_provider.dart';
import '../domain/nutrition_overview.dart';

abstract class NutritionRepository {
  Future<NutritionOverviewData> fetchOverview({
    required DateTime date,
    required NutritionRangeOption range,
  });

  Future<NutritionMacroDetail> fetchMacroDetail({
    required NutritionMetricType macroType,
    required DateTime date,
    required NutritionRangeOption range,
  });
}

class ApiNutritionRepository implements NutritionRepository {
  const ApiNutritionRepository({required this.apiClient});

  final AppApiClient apiClient;

  @override
  Future<NutritionOverviewData> fetchOverview({
    required DateTime date,
    required NutritionRangeOption range,
  }) async {
    final payload = await apiClient.getMap(
      '/nutrition/overview',
      queryParameters: {
        'range': range.apiValue,
        'date': formatApiDate(date),
      },
    );
    return NutritionOverviewData.fromJson(payload);
  }

  @override
  Future<NutritionMacroDetail> fetchMacroDetail({
    required NutritionMetricType macroType,
    required DateTime date,
    required NutritionRangeOption range,
  }) async {
    final payload = await apiClient.getMap(
      '/nutrition/macro/${macroType.apiValue}',
      queryParameters: {
        'range': range.apiValue,
        'date': formatApiDate(date),
      },
    );
    return NutritionMacroDetail.fromJson(payload);
  }
}

final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  final apiClient = ref.watch(appApiClientProvider);
  return ApiNutritionRepository(apiClient: apiClient);
});
