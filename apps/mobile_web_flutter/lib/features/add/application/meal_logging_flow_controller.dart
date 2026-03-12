import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../today/domain/today_dashboard.dart';
import '../infrastructure/meal_logging_repository.dart';

class MealLoggingFlowState {
  const MealLoggingFlowState({
    required this.selectedDate,
    required this.mealSection,
    required this.submission,
  });

  final DateTime selectedDate;
  final TodayMealSectionCode mealSection;
  final AsyncValue<void> submission;

  MealLoggingFlowState copyWith({
    DateTime? selectedDate,
    TodayMealSectionCode? mealSection,
    AsyncValue<void>? submission,
  }) {
    return MealLoggingFlowState(
      selectedDate: selectedDate ?? this.selectedDate,
      mealSection: mealSection ?? this.mealSection,
      submission: submission ?? this.submission,
    );
  }
}

class MealLoggingFlowController extends Notifier<MealLoggingFlowState> {
  late final MealLoggingRepository _repository;

  @override
  MealLoggingFlowState build() {
    _repository = ref.watch(mealLoggingRepositoryProvider);
    return MealLoggingFlowState(
      selectedDate: DateUtils.dateOnly(DateTime.now()),
      mealSection: TodayMealSectionCode.breakfast,
      submission: const AsyncData(null),
    );
  }

  void seed({
    DateTime? selectedDate,
    TodayMealSectionCode? mealSection,
  }) {
    state = state.copyWith(
      selectedDate: selectedDate == null ? null : DateUtils.dateOnly(selectedDate),
      mealSection: mealSection,
      submission: const AsyncData(null),
    );
  }

  void setSelectedDate(DateTime date) {
    state = state.copyWith(selectedDate: DateUtils.dateOnly(date));
  }

  void setMealSection(TodayMealSectionCode mealSection) {
    state = state.copyWith(mealSection: mealSection);
  }

  void clearSubmissionState() {
    state = state.copyWith(submission: const AsyncData(null));
  }

  Future<bool> createMealEntry({
    required String foodId,
    required double quantity,
    required String unit,
    String? notes,
  }) async {
    state = state.copyWith(submission: const AsyncLoading());
    try {
      await _repository.createMealEntry(
        date: state.selectedDate,
        mealSection: state.mealSection,
        foodId: foodId,
        quantity: quantity,
        unit: unit,
        notes: notes,
      );
      state = state.copyWith(submission: const AsyncData(null));
      return true;
    } catch (error, stackTrace) {
      state = state.copyWith(submission: AsyncError(error, stackTrace));
      return false;
    }
  }

  Future<bool> updateMealEntry({
    required String entryId,
    required double quantity,
    required String unit,
    String? notes,
  }) async {
    state = state.copyWith(submission: const AsyncLoading());
    try {
      await _repository.updateMealEntry(
        entryId: entryId,
        quantity: quantity,
        unit: unit,
        notes: notes,
      );
      state = state.copyWith(submission: const AsyncData(null));
      return true;
    } catch (error, stackTrace) {
      state = state.copyWith(submission: AsyncError(error, stackTrace));
      return false;
    }
  }

  Future<bool> deleteMealEntry(String entryId) async {
    state = state.copyWith(submission: const AsyncLoading());
    try {
      await _repository.deleteMealEntry(entryId);
      state = state.copyWith(submission: const AsyncData(null));
      return true;
    } catch (error, stackTrace) {
      state = state.copyWith(submission: AsyncError(error, stackTrace));
      return false;
    }
  }
}

final mealLoggingFlowControllerProvider =
    NotifierProvider<MealLoggingFlowController, MealLoggingFlowState>(
  MealLoggingFlowController.new,
);
