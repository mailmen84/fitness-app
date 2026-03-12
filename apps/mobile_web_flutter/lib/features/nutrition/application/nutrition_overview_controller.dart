import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/nutrition_overview.dart';
import '../infrastructure/nutrition_repository.dart';

class NutritionOverviewViewState {
  const NutritionOverviewViewState({
    required this.anchorDate,
    required this.selectedRange,
    required this.overview,
  });

  final DateTime anchorDate;
  final NutritionRangeOption selectedRange;
  final AsyncValue<NutritionOverviewData> overview;

  NutritionOverviewViewState copyWith({
    DateTime? anchorDate,
    NutritionRangeOption? selectedRange,
    AsyncValue<NutritionOverviewData>? overview,
  }) {
    return NutritionOverviewViewState(
      anchorDate: anchorDate ?? this.anchorDate,
      selectedRange: selectedRange ?? this.selectedRange,
      overview: overview ?? this.overview,
    );
  }
}

class NutritionOverviewController extends Notifier<NutritionOverviewViewState> {
  late final NutritionRepository _repository;

  @override
  NutritionOverviewViewState build() {
    _repository = ref.watch(nutritionRepositoryProvider);
    final initialDate = DateUtils.dateOnly(DateTime.now());
    Future<void>.microtask(() => loadOverview());
    return NutritionOverviewViewState(
      anchorDate: initialDate,
      selectedRange: NutritionRangeOption.day,
      overview: const AsyncLoading(),
    );
  }

  Future<void> loadOverview({
    DateTime? anchorDate,
    NutritionRangeOption? selectedRange,
  }) async {
    final nextAnchorDate = DateUtils.dateOnly(anchorDate ?? state.anchorDate);
    final nextSelectedRange = selectedRange ?? state.selectedRange;

    state = state.copyWith(
      anchorDate: nextAnchorDate,
      selectedRange: nextSelectedRange,
      overview: const AsyncLoading(),
    );

    try {
      final overview = await _repository.fetchOverview(
        date: nextAnchorDate,
        range: nextSelectedRange,
      );
      state = state.copyWith(overview: AsyncData(overview));
    } catch (error, stackTrace) {
      state = state.copyWith(overview: AsyncError(error, stackTrace));
    }
  }

  Future<void> setRange(NutritionRangeOption selectedRange) async {
    if (selectedRange == state.selectedRange && state.overview.hasValue) {
      return;
    }
    await loadOverview(selectedRange: selectedRange);
  }

  Future<void> loadPreviousRange() async {
    await loadOverview(anchorDate: _shiftAnchorDate(-1));
  }

  Future<void> loadNextRange() async {
    await loadOverview(anchorDate: _shiftAnchorDate(1));
  }

  Future<void> jumpToToday() async {
    await loadOverview(anchorDate: DateTime.now());
  }

  Future<void> reload() async {
    await loadOverview();
  }

  Future<void> retry() async {
    await reload();
  }

  DateTime _shiftAnchorDate(int direction) {
    return switch (state.selectedRange) {
      NutritionRangeOption.day =>
        state.anchorDate.add(Duration(days: direction)),
      NutritionRangeOption.week =>
        state.anchorDate.add(Duration(days: 7 * direction)),
      NutritionRangeOption.month => _shiftMonth(state.anchorDate, direction),
    };
  }

  DateTime _shiftMonth(DateTime anchorDate, int monthDelta) {
    final monthStart = DateTime(anchorDate.year, anchorDate.month + monthDelta, 1);
    final lastDayOfMonth = DateTime(
      monthStart.year,
      monthStart.month + 1,
      0,
    ).day;
    final targetDay = anchorDate.day > lastDayOfMonth ? lastDayOfMonth : anchorDate.day;
    return DateTime(monthStart.year, monthStart.month, targetDay);
  }
}

final nutritionOverviewControllerProvider =
    NotifierProvider<NutritionOverviewController, NutritionOverviewViewState>(
  NutritionOverviewController.new,
);

