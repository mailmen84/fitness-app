import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/progress_models.dart';
import '../infrastructure/progress_repository.dart';

class WeightLogListController extends AsyncNotifier<List<WeightLogEntry>> {
  late final ProgressRepository _repository;

  @override
  FutureOr<List<WeightLogEntry>> build() async {
    _repository = ref.watch(progressRepositoryProvider);
    return _repository.fetchWeightLogs();
  }

  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.fetchWeightLogs);
  }

  Future<void> reload() async {
    await load();
  }
}

final weightLogListControllerProvider =
    AsyncNotifierProvider<WeightLogListController, List<WeightLogEntry>>(
      WeightLogListController.new,
    );
