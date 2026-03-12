import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/more_models.dart';
import '../infrastructure/more_repository.dart';

class PreferencesSubmissionController
    extends AutoDisposeNotifier<AsyncValue<void>> {
  late final MoreRepository _repository;

  @override
  AsyncValue<void> build() {
    _repository = ref.watch(moreRepositoryProvider);
    return const AsyncData(null);
  }

  Future<PreferenceData?> submit({
    required String unitSystem,
    required String timezone,
    required String weekStartsOn,
    double? dailyCalorieTarget,
    double? dailyProteinTarget,
    required bool onboardingCompleted,
  }) async {
    state = const AsyncLoading();

    try {
      final updated = await _repository.putPreferences(
        unitSystem: unitSystem,
        timezone: timezone,
        weekStartsOn: weekStartsOn,
        dailyCalorieTarget: dailyCalorieTarget,
        dailyProteinTarget: dailyProteinTarget,
        onboardingCompleted: onboardingCompleted,
      );
      state = const AsyncData(null);
      return updated;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }
}

final preferencesSubmissionControllerProvider =
    NotifierProvider.autoDispose<PreferencesSubmissionController, AsyncValue<void>>(
      PreferencesSubmissionController.new,
    );