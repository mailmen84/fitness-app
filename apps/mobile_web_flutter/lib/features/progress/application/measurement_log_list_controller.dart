import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/progress_models.dart';
import '../infrastructure/progress_repository.dart';

class MeasurementLogListController
    extends AsyncNotifier<List<MeasurementLogEntry>> {
  late final ProgressRepository _repository;

  @override
  FutureOr<List<MeasurementLogEntry>> build() async {
    _repository = ref.watch(progressRepositoryProvider);
    return _repository.fetchMeasurementLogs();
  }

  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.fetchMeasurementLogs);
  }

  Future<void> reload() async {
    await load();
  }
}

final measurementLogListControllerProvider = AsyncNotifierProvider<
    MeasurementLogListController, List<MeasurementLogEntry>>(
  MeasurementLogListController.new,
);
