import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/meal_logging_models.dart';
import '../infrastructure/meal_logging_repository.dart';

class FoodSearchState {
  const FoodSearchState({
    required this.query,
    required this.results,
  });

  final String query;
  final AsyncValue<List<FoodSearchResult>> results;

  bool get hasQuery => query.trim().isNotEmpty;

  FoodSearchState copyWith({
    String? query,
    AsyncValue<List<FoodSearchResult>>? results,
  }) {
    return FoodSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
    );
  }
}

class FoodSearchController extends Notifier<FoodSearchState> {
  late final MealLoggingRepository _repository;

  @override
  FoodSearchState build() {
    _repository = ref.watch(mealLoggingRepositoryProvider);
    return const FoodSearchState(
      query: '',
      results: AsyncData(<FoodSearchResult>[]),
    );
  }

  Future<void> search(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      state = const FoodSearchState(
        query: '',
        results: AsyncData(<FoodSearchResult>[]),
      );
      return;
    }

    state = state.copyWith(
      query: normalizedQuery,
      results: const AsyncLoading(),
    );

    try {
      final items = await _repository.searchFoods(normalizedQuery);
      state = state.copyWith(results: AsyncData(items));
    } catch (error, stackTrace) {
      state = state.copyWith(results: AsyncError(error, stackTrace));
    }
  }

  Future<void> retry() async {
    await search(state.query);
  }
}

final foodSearchControllerProvider =
    NotifierProvider<FoodSearchController, FoodSearchState>(
  FoodSearchController.new,
);

final foodDetailProvider = FutureProvider.family<FoodDetail, String>((ref, foodId) async {
  final repository = ref.watch(mealLoggingRepositoryProvider);
  return repository.getFoodDetail(foodId);
});
