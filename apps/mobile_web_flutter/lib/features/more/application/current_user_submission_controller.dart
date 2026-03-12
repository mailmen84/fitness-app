import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/more_models.dart';
import '../infrastructure/more_repository.dart';

class CurrentUserSubmissionController
    extends AutoDisposeNotifier<AsyncValue<void>> {
  late final MoreRepository _repository;

  @override
  AsyncValue<void> build() {
    _repository = ref.watch(moreRepositoryProvider);
    return const AsyncData(null);
  }

  Future<CurrentUserData?> submit({
    required String email,
    String? displayName,
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    double? heightCm,
    String? bio,
  }) async {
    state = const AsyncLoading();

    try {
      final updated = await _repository.updateCurrentUser(
        email: email,
        displayName: displayName,
        firstName: firstName,
        lastName: lastName,
        birthDate: birthDate,
        heightCm: heightCm,
        bio: bio,
      );
      state = const AsyncData(null);
      return updated;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }
}

final currentUserSubmissionControllerProvider =
    NotifierProvider.autoDispose<CurrentUserSubmissionController, AsyncValue<void>>(
      CurrentUserSubmissionController.new,
    );