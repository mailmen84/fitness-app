import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_web_flutter/features/nutrition/domain/nutrition_overview.dart';
import 'package:mobile_web_flutter/features/nutrition/infrastructure/nutrition_repository.dart';
import 'package:mobile_web_flutter/features/nutrition/presentation/nutrition_screen.dart';

class _FakeNutritionRepository implements NutritionRepository {
  @override
  Future<NutritionOverviewData> fetchOverview({
    required DateTime date,
    required NutritionRangeOption range,
  }) async {
    return NutritionOverviewData(
      range: range,
      anchorDate: date,
      periodStart: date,
      periodEnd: date,
      caloriesTotal: 1820,
      proteinTotal: 132,
      carbsTotal: 168,
      fatTotal: 58,
      targets: const NutritionTargets(
        calories: 2100,
        protein: 140,
      ),
      categoryRows: const [
        NutritionCategoryRow(
          code: NutritionMetricType.calories,
          title: 'Calories',
          amount: 1820,
          unit: 'kcal',
          target: 2100,
          progressRatio: 0.8667,
        ),
        NutritionCategoryRow(
          code: NutritionMetricType.protein,
          title: 'Protein',
          amount: 132,
          unit: 'g',
          target: 140,
          progressRatio: 0.9429,
        ),
      ],
      topContributors: const [
        NutritionContributor(
          entryId: 'entry-1',
          mealId: 'meal-1',
          mealSectionCode: 'lunch',
          foodName: 'Greek Yogurt Bowl',
          quantity: 1,
          unit: 'serving',
          calories: 420,
          protein: 28,
          carbs: 36,
          fat: 12,
        ),
      ],
    );
  }

  @override
  Future<NutritionMacroDetail> fetchMacroDetail({
    required NutritionMetricType macroType,
    required DateTime date,
    required NutritionRangeOption range,
  }) async {
    return NutritionMacroDetail(
      macroType: macroType,
      range: range,
      anchorDate: date,
      periodStart: date,
      periodEnd: date,
      total: 132,
      unit: 'g',
      target: 140,
      contributors: const [
        NutritionMacroContributor(
          entryId: 'entry-1',
          mealId: 'meal-1',
          mealSectionCode: 'lunch',
          foodName: 'Greek Yogurt Bowl',
          quantity: 1,
          unit: 'serving',
          value: 28,
          shareRatio: 0.2121,
        ),
      ],
    );
  }
}

void main() {
  testWidgets('renders the nutrition overview with summaries and contributors', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nutritionRepositoryProvider.overrideWithValue(
            _FakeNutritionRepository(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: NutritionScreen()),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Nutrition overview'), findsOneWidget);
    expect(find.text('Calories'), findsWidgets);
    expect(find.text('Top contributors'), findsOneWidget);
    expect(find.text('Greek Yogurt Bowl'), findsOneWidget);
    expect(find.text('Protein'), findsWidgets);
  });
}
