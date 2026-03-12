import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../infrastructure/progress_repository.dart';

class WeightLogSubmissionController
    extends AutoDisposeNotifier<AsyncValue<void>> {
  late final ProgressRepository _repository;

  @override
  AsyncValue<void> build() {
    _repository = ref.watch(progressRepositoryProvider);
    return const AsyncData(null);
  }

  Future<bool> submit({
    required DateTime measuredAt,
    required double weight,
    required String unit,
    String? note,
  }) async {
    state = const AsyncLoading();

    try {
      await _repository.createWeightLog(
        measuredAt: measuredAt,
        weight: weight,
        unit: unit,
        note: note,
      );
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}

final weightLogSubmissionControllerProvider =
    NotifierProvider.autoDispose<WeightLogSubmissionController, AsyncValue<void>>(
      WeightLogSubmissionController.new,
    );
