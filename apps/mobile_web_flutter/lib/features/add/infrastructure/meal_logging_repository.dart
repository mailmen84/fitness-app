import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_date_formatter.dart';
import '../../../core/network/app_api_client.dart';
import '../../shared/application/api_client_provider.dart';
import '../../today/domain/today_dashboard.dart';
import '../domain/meal_logging_models.dart';

abstract class MealLoggingRepository {
  Future<List<FoodSearchResult>> searchFoods(String query);
  Future<FoodDetail> getFoodDetail(String foodId);
  Future<TodayMealEntry> createMealEntry({
    required DateTime date,
    required TodayMealSectionCode mealSection,
    required String foodId,
    required double quantity,
    required String unit,
    String? notes,
  });
  Future<TodayMealEntry> updateMealEntry({
    required String entryId,
    required double quantity,
    required String unit,
    String? notes,
  });
  Future<void> deleteMealEntry(String entryId);
}

class ApiMealLoggingRepository implements MealLoggingRepository {
  const ApiMealLoggingRepository({required this.apiClient});

  final AppApiClient apiClient;

  @override
  Future<List<FoodSearchResult>> searchFoods(String query) async {
    final payload = await apiClient.getMap(
      '/foods/search',
      queryParameters: {'q': query},
    );
    final items = payload['items'] as List<dynamic>? ?? const [];
    return items
        .map((item) => FoodSearchResult.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<FoodDetail> getFoodDetail(String foodId) async {
    final payload = await apiClient.getMap('/foods/$foodId');
    return FoodDetail.fromJson(payload);
  }

  @override
  Future<TodayMealEntry> createMealEntry({
    required DateTime date,
    required TodayMealSectionCode mealSection,
    required String foodId,
    required double quantity,
    required String unit,
    String? notes,
  }) async {
    final payload = await apiClient.postJsonMap(
      '/meals/entries',
      body: {
        'date': formatApiDate(date),
        'meal_section': mealSection.apiValue,
        'food_id': foodId,
        'quantity': quantity,
        'unit': unit,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
    return TodayMealEntry.fromJson(payload);
  }

  @override
  Future<TodayMealEntry> updateMealEntry({
    required String entryId,
    required double quantity,
    required String unit,
    String? notes,
  }) async {
    final payload = await apiClient.patchJsonMap(
      '/meals/entries/$entryId',
      body: {
        'quantity': quantity,
        'unit': unit,
        if (notes != null) 'notes': notes.trim().isEmpty ? null : notes.trim(),
      },
    );
    return TodayMealEntry.fromJson(payload);
  }

  @override
  Future<void> deleteMealEntry(String entryId) async {
    await apiClient.delete('/meals/entries/$entryId');
  }
}

final mealLoggingRepositoryProvider = Provider<MealLoggingRepository>((ref) {
  final apiClient = ref.watch(appApiClientProvider);
  return ApiMealLoggingRepository(apiClient: apiClient);
});
