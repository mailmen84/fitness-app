import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/today_dashboard.dart';
import '../infrastructure/today_dashboard_repository.dart';

class TodayDashboardViewState {
  const TodayDashboardViewState({
    required this.selectedDate,
    required this.dashboard,
  });

  final DateTime selectedDate;
  final AsyncValue<TodayDashboardData> dashboard;

  TodayDashboardViewState copyWith({
    DateTime? selectedDate,
    AsyncValue<TodayDashboardData>? dashboard,
  }) {
    return TodayDashboardViewState(
      selectedDate: selectedDate ?? this.selectedDate,
      dashboard: dashboard ?? this.dashboard,
    );
  }
}

class TodayDashboardController extends Notifier<TodayDashboardViewState> {
  late final TodayDashboardRepository _repository;

  @override
  TodayDashboardViewState build() {
    _repository = ref.watch(todayDashboardRepositoryProvider);
    final initialDate = DateUtils.dateOnly(DateTime.now());
    Future<void>.microtask(() => loadForDate(initialDate));
    return TodayDashboardViewState(
      selectedDate: initialDate,
      dashboard: const AsyncLoading(),
    );
  }

  Future<void> loadForDate(DateTime date) async {
    final selectedDate = DateUtils.dateOnly(date);
    state = state.copyWith(
      selectedDate: selectedDate,
      dashboard: const AsyncLoading(),
    );

    try {
      final dashboard = await _repository.fetchDay(selectedDate);
      state = state.copyWith(dashboard: AsyncData(dashboard));
    } catch (error, stackTrace) {
      state = state.copyWith(dashboard: AsyncError(error, stackTrace));
    }
  }

  Future<void> loadPreviousDay() async {
    await loadForDate(state.selectedDate.subtract(const Duration(days: 1)));
  }

  Future<void> loadNextDay() async {
    await loadForDate(state.selectedDate.add(const Duration(days: 1)));
  }

  Future<void> jumpToToday() async {
    await loadForDate(DateTime.now());
  }

  Future<void> retry() async {
    await loadForDate(state.selectedDate);
  }
}

final todayDashboardControllerProvider =
    NotifierProvider<TodayDashboardController, TodayDashboardViewState>(
  TodayDashboardController.new,
);
