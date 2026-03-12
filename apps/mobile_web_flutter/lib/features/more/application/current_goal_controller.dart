import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/more_models.dart';
import '../infrastructure/more_repository.dart';

class CurrentGoalController extends AsyncNotifier<CurrentGoalData?> {
  late final MoreRepository _repository;

  @override
  FutureOr<CurrentGoalData?> build() async {
    _repository = ref.watch(moreRepositoryProvider);
    return _repository.fetchCurrentGoal();
  }

  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.fetchCurrentGoal);
  }

  Future<void> reload() async {
    await load();
  }
}

final currentGoalControllerProvider =
    AsyncNotifierProvider<CurrentGoalController, CurrentGoalData?>(
  CurrentGoalController.new,
);
