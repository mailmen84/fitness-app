import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/more_models.dart';
import '../infrastructure/more_repository.dart';

class PreferencesController extends AsyncNotifier<PreferenceData> {
  late final MoreRepository _repository;

  @override
  FutureOr<PreferenceData> build() async {
    _repository = ref.watch(moreRepositoryProvider);
    return _repository.fetchPreferences();
  }

  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.fetchPreferences);
  }

  Future<void> reload() async {
    await load();
  }
}

final preferencesControllerProvider =
    AsyncNotifierProvider<PreferencesController, PreferenceData>(
  PreferencesController.new,
);
