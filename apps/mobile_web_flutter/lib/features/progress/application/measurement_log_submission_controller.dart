import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../infrastructure/progress_repository.dart';

class MeasurementLogSubmissionController
    extends AutoDisposeNotifier<AsyncValue<void>> {
  late final ProgressRepository _repository;

  @override
  AsyncValue<void> build() {
    _repository = ref.watch(progressRepositoryProvider);
    return const AsyncData(null);
  }

  Future<bool> submit({
    required String measurementType,
    required DateTime measuredAt,
    required double value,
    required String unit,
    String? note,
  }) async {
    state = const AsyncLoading();

    try {
      await _repository.createMeasurementLog(
        measurementType: measurementType,
        measuredAt: measuredAt,
        value: value,
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

final measurementLogSubmissionControllerProvider =
    NotifierProvider.autoDispose<MeasurementLogSubmissionController, AsyncValue<void>>(
      MeasurementLogSubmissionController.new,
    );
