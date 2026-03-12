import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_web_flutter/features/progress/domain/progress_models.dart';
import 'package:mobile_web_flutter/features/progress/infrastructure/progress_repository.dart';
import 'package:mobile_web_flutter/features/progress/presentation/progress_screen.dart';

class _FakeProgressRepository implements ProgressRepository {
  @override
  Future<ProgressOverviewData> fetchOverview() async {
    return ProgressOverviewData(
      latestWeight: WeightLogEntry(
        id: 'weight-1',
        measuredAt: DateTime(2026, 3, 11, 7, 30),
        weight: 84.2,
        unit: 'kg',
        note: 'Morning check-in',
      ),
      previousWeight: WeightLogEntry(
        id: 'weight-2',
        measuredAt: DateTime(2026, 3, 4, 7, 30),
        weight: 85.0,
        unit: 'kg',
        note: null,
      ),
      weightChange: -0.8,
      weightChangeUnit: 'kg',
      latestMeasurements: [
        LatestMeasurementSummary(
          measurementType: 'waist',
          measuredAt: DateTime(2026, 3, 10, 18, 0),
          value: 82,
          unit: 'cm',
        ),
      ],
      currentGoal: const ProgressGoalSummary(
        id: 'goal-1',
        code: 'cut',
        title: 'Cut to 82 kg',
        targetValue: 82,
        targetUnit: 'kg',
      ),
    );
  }

  @override
  Future<List<WeightLogEntry>> fetchWeightLogs() async => const [];

  @override
  Future<WeightLogEntry> createWeightLog({
    required DateTime measuredAt,
    required double weight,
    required String unit,
    String? note,
  }) async {
    return WeightLogEntry(
      id: 'new-weight',
      measuredAt: measuredAt,
      weight: weight,
      unit: unit,
      note: note,
    );
  }

  @override
  Future<List<MeasurementLogEntry>> fetchMeasurementLogs() async => const [];

  @override
  Future<MeasurementLogEntry> createMeasurementLog({
    required String measurementType,
    required DateTime measuredAt,
    required double value,
    required String unit,
    String? note,
  }) async {
    return MeasurementLogEntry(
      id: 'new-measurement',
      measurementType: measurementType,
      measuredAt: measuredAt,
      value: value,
      unit: unit,
      note: note,
    );
  }
}

void main() {
  testWidgets('renders the Progress overview with weight and measurement summaries', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          progressRepositoryProvider.overrideWithValue(_FakeProgressRepository()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ProgressScreen()),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Progress overview'), findsOneWidget);
    expect(find.text('Latest weight'), findsOneWidget);
    expect(find.text('84.2 kg'), findsOneWidget);
    expect(find.text('Latest measurements'), findsOneWidget);
    expect(find.text('Waist'), findsOneWidget);
    expect(find.text('Cut to 82 kg'), findsOneWidget);
  });
}
