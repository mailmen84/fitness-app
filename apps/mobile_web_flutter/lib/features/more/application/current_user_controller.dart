import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/more_models.dart';
import '../infrastructure/more_repository.dart';

class CurrentUserController extends AsyncNotifier<CurrentUserData> {
  late final MoreRepository _repository;

  @override
  FutureOr<CurrentUserData> build() async {
    _repository = ref.watch(moreRepositoryProvider);
    return _repository.fetchCurrentUser();
  }

  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.fetchCurrentUser);
  }

  Future<void> reload() async {
    await load();
  }
}

final currentUserControllerProvider =
    AsyncNotifierProvider<CurrentUserController, CurrentUserData>(
  CurrentUserController.new,
);
