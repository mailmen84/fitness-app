import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_web_flutter/features/add/domain/meal_logging_models.dart';
import 'package:mobile_web_flutter/features/add/infrastructure/meal_logging_repository.dart';
import 'package:mobile_web_flutter/features/add/presentation/food_detail_screen.dart';
import 'package:mobile_web_flutter/features/today/domain/today_dashboard.dart';

class _FakeMealLoggingRepository implements MealLoggingRepository {
  const _FakeMealLoggingRepository();

  @override
  Future<TodayMealEntry> createMealEntry({
    required DateTime date,
    required TodayMealSectionCode mealSection,
    required String foodId,
    required double quantity,
    required String unit,
    String? notes,
  }) async {
    return TodayMealEntry(
      id: 'entry-1',
      mealId: 'meal-1',
      foodId: foodId,
      foodName: 'Greek Yogurt',
      quantity: quantity,
      unit: unit,
      calories: 100,
      protein: 17,
      carbs: 6,
      fat: 0,
      notes: notes,
    );
  }

  @override
  Future<void> deleteMealEntry(String entryId) async {}

  @override
  Future<FoodDetail> getFoodDetail(String foodId) async {
    if (foodId == 'food-2') {
      return const FoodDetail(
        id: 'food-2',
        name: 'Blueberries',
        brand: 'Berry Farm',
        defaultServingAmount: 1.25,
        defaultServingUnit: 'cup',
        isVerified: true,
        calories: 105,
        protein: 1.3,
        carbs: 27,
        fat: 0.5,
        nutrients: [
          FoodNutrient(
            code: 'fiber',
            name: 'Fiber',
            amount: 4,
            unit: 'g',
          ),
        ],
      );
    }

    return const FoodDetail(
      id: 'food-1',
      name: 'Greek Yogurt',
      brand: 'Test Dairy',
      defaultServingAmount: 2,
      defaultServingUnit: 'serving',
      isVerified: true,
      calories: 100,
      protein: 17,
      carbs: 6,
      fat: 0,
      nutrients: [
        FoodNutrient(
          code: 'protein',
          name: 'Protein',
          amount: 17,
          unit: 'g',
        ),
      ],
    );
  }

  @override
  Future<List<FoodSearchResult>> searchFoods(String query) async => const [];

  @override
  Future<TodayMealEntry> updateMealEntry({
    required String entryId,
    required double quantity,
    required String unit,
    String? notes,
  }) async {
    return TodayMealEntry(
      id: entryId,
      mealId: 'meal-1',
      foodId: 'food-1',
      foodName: 'Greek Yogurt',
      quantity: quantity,
      unit: unit,
      calories: 100,
      protein: 17,
      carbs: 6,
      fat: 0,
      notes: notes,
    );
  }
}

TextFormField _textFormField(WidgetTester tester, String label) {
  return tester.widget<TextFormField>(
    find.byWidgetPredicate(
      (widget) =>
          widget is TextFormField && widget.decoration?.labelText == label,
      description: 'TextFormField($label)',
    ),
  );
}

Future<void> _pumpFoodDetailScreen(WidgetTester tester, String foodId) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        mealLoggingRepositoryProvider.overrideWithValue(
          const _FakeMealLoggingRepository(),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: FoodDetailScreen(foodId: foodId),
        ),
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  testWidgets('food detail seeds the loaded serving values without exceptions', (
    tester,
  ) async {
    await _pumpFoodDetailScreen(tester, 'food-1');

    expect(tester.takeException(), isNull);
    expect(_textFormField(tester, 'Amount').controller?.text, '2');
    expect(_textFormField(tester, 'Notes').controller?.text, '');
    expect(find.text('Greek Yogurt'), findsOneWidget);
  });

  testWidgets('food detail reseeds when the selected food changes', (
    tester,
  ) async {
    await _pumpFoodDetailScreen(tester, 'food-1');
    expect(_textFormField(tester, 'Amount').controller?.text, '2');

    await _pumpFoodDetailScreen(tester, 'food-2');

    expect(tester.takeException(), isNull);
    expect(_textFormField(tester, 'Amount').controller?.text, '1.25');
    expect(find.text('Blueberries'), findsOneWidget);
  });
}
