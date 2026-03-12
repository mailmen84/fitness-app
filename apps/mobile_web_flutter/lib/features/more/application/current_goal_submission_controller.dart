import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/more_models.dart';
import '../infrastructure/more_repository.dart';

class CurrentGoalSubmissionController
    extends AutoDisposeNotifier<AsyncValue<void>> {
  late final MoreRepository _repository;

  @override
  AsyncValue<void> build() {
    _repository = ref.watch(moreRepositoryProvider);
    return const AsyncData(null);
  }

  Future<CurrentGoalData?> submit({
    required String code,
    required String title,
    double? targetValue,
    String? targetUnit,
    DateTime? startsOn,
    DateTime? endsOn,
    String? notes,
  }) async {
    state = const AsyncLoading();

    try {
      final updated = await _repository.putCurrentGoal(
        code: code,
        title: title,
        targetValue: targetValue,
        targetUnit: targetUnit,
        startsOn: startsOn,
        endsOn: endsOn,
        notes: notes,
      );
      state = const AsyncData(null);
      return updated;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }
}

final currentGoalSubmissionControllerProvider =
    NotifierProvider.autoDispose<CurrentGoalSubmissionController, AsyncValue<void>>(
      CurrentGoalSubmissionController.new,
    );