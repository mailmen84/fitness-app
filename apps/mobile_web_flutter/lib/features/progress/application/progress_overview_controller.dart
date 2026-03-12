import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/progress_models.dart';
import '../infrastructure/progress_repository.dart';

class ProgressOverviewController extends AsyncNotifier<ProgressOverviewData> {
  late final ProgressRepository _repository;

  @override
  FutureOr<ProgressOverviewData> build() async {
    _repository = ref.watch(progressRepositoryProvider);
    return _repository.fetchOverview();
  }

  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.fetchOverview);
  }

  Future<void> reload() async {
    await load();
  }
}

final progressOverviewControllerProvider =
    AsyncNotifierProvider<ProgressOverviewController, ProgressOverviewData>(
      ProgressOverviewController.new,
    );
