import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_web_flutter/features/today/domain/today_dashboard.dart';
import 'package:mobile_web_flutter/features/today/infrastructure/today_dashboard_repository.dart';
import 'package:mobile_web_flutter/features/today/presentation/today_screen.dart';

class _FakeTodayDashboardRepository implements TodayDashboardRepository {
  @override
  Future<TodayDashboardData> fetchDay(DateTime date) async {
    return TodayDashboardData(
      date: date,
      caloriesTotal: 1200,
      proteinTotal: 90,
      carbsTotal: 110,
      fatTotal: 35,
      mealSections: const [
        TodayMealSection(
          code: TodayMealSectionCode.breakfast,
          caloriesTotal: 300,
          proteinTotal: 20,
          carbsTotal: 32,
          fatTotal: 8,
          entries: [
            TodayMealEntry(
              id: 'breakfast-entry',
              mealId: 'breakfast-meal',
              foodId: 'oats-food',
              foodName: 'Oats and berries',
              quantity: 1,
              unit: 'bowl',
              calories: 300,
              protein: 20,
              carbs: 32,
              fat: 8,
            ),
          ],
        ),
        TodayMealSection.empty(TodayMealSectionCode.lunch),
        TodayMealSection.empty(TodayMealSectionCode.dinner),
        TodayMealSection.empty(TodayMealSectionCode.snacks),
      ],
    );
  }
}

void main() {
  testWidgets('renders the Today dashboard with summary and meal cards', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayDashboardRepositoryProvider.overrideWithValue(
            _FakeTodayDashboardRepository(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: TodayScreen()),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Quick actions'), findsOneWidget);
    expect(find.text('Calories'), findsOneWidget);
    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.text('Oats and berries'), findsOneWidget);
    expect(find.text('Add to meal'), findsOneWidget);
  });
}
