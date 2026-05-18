import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_date_formatter.dart';
import '../../../core/network/app_api_client.dart';
import '../../shared/application/api_client_provider.dart';
import '../domain/more_models.dart';

abstract class MoreRepository {
  Future<CurrentUserData> fetchCurrentUser();
  Future<CurrentUserData> updateCurrentUser({
    required String email,
    String? displayName,
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    double? heightCm,
    String? bio,
  });
  Future<CurrentGoalData?> fetchCurrentGoal();
  Future<CurrentGoalData> putCurrentGoal({
    required String code,
    required String title,
    double? targetValue,
    String? targetUnit,
    DateTime? startsOn,
    DateTime? endsOn,
    String? notes,
  });
  Future<PreferenceData> fetchPreferences();
  Future<PreferenceData> putPreferences({
    required String unitSystem,
    required String timezone,
    required String weekStartsOn,
    double? dailyCalorieTarget,
    double? dailyProteinTarget,
    double? dailyCarbsTarget,
    double? dailyFatTarget,
    required bool onboardingCompleted,
  });
}

class ApiMoreRepository implements MoreRepository {
  const ApiMoreRepository({required this.apiClient});

  final AppApiClient apiClient;

  String? _optionalText(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Future<CurrentUserData> fetchCurrentUser() async {
    final payload = await apiClient.getMap('/users/me');
    return CurrentUserData.fromJson(payload);
  }

  @override
  Future<CurrentUserData> updateCurrentUser({
    required String email,
    String? displayName,
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    double? heightCm,
    String? bio,
  }) async {
    final payload = await apiClient.patchJsonMap(
      '/users/me',
      body: {
        'email': email.trim(),
        'display_name': _optionalText(displayName),
        'first_name': _optionalText(firstName),
        'last_name': _optionalText(lastName),
        'birth_date': birthDate == null ? null : formatApiDate(birthDate),
        'height_cm': heightCm,
        'bio': _optionalText(bio),
      },
    );
    return CurrentUserData.fromJson(payload);
  }

  @override
  Future<CurrentGoalData?> fetchCurrentGoal() async {
    final payload = await apiClient.get('/goals/current');
    if (payload == null) {
      return null;
    }
    if (payload is Map<String, dynamic>) {
      return CurrentGoalData.fromJson(payload);
    }
    if (payload is Map) {
      return CurrentGoalData.fromJson(Map<String, dynamic>.from(payload));
    }
    throw const ApiException(
      message: 'Expected the current goal response to be an object or null.',
    );
  }

  @override
  Future<CurrentGoalData> putCurrentGoal({
    required String code,
    required String title,
    double? targetValue,
    String? targetUnit,
    DateTime? startsOn,
    DateTime? endsOn,
    String? notes,
  }) async {
    final payload = await apiClient.putJsonMap(
      '/goals/current',
      body: {
        'code': code,
        'title': title.trim(),
        'target_value': targetValue,
        'target_unit': _optionalText(targetUnit),
        'starts_on': startsOn == null ? null : formatApiDate(startsOn),
        'ends_on': endsOn == null ? null : formatApiDate(endsOn),
        'notes': _optionalText(notes),
      },
    );
    return CurrentGoalData.fromJson(payload);
  }

  @override
  Future<PreferenceData> fetchPreferences() async {
    final payload = await apiClient.getMap('/preferences');
    return PreferenceData.fromJson(payload);
  }

  @override
  Future<PreferenceData> putPreferences({
    required String unitSystem,
    required String timezone,
    required String weekStartsOn,
    double? dailyCalorieTarget,
    double? dailyProteinTarget,
    double? dailyCarbsTarget,
    double? dailyFatTarget,
    required bool onboardingCompleted,
  }) async {
    final payload = await apiClient.putJsonMap(
      '/preferences',
      body: {
        'unit_system': unitSystem,
        'timezone': timezone.trim(),
        'week_starts_on': weekStartsOn,
        'daily_calorie_target': dailyCalorieTarget,
        'daily_protein_target': dailyProteinTarget,
        'daily_carbs_target': dailyCarbsTarget,
        'daily_fat_target': dailyFatTarget,
        'onboarding_completed': onboardingCompleted,
      },
    );
    return PreferenceData.fromJson(payload);
  }
}

final moreRepositoryProvider = Provider<MoreRepository>((ref) {
  final apiClient = ref.watch(appApiClientProvider);
  return ApiMoreRepository(apiClient: apiClient);
});
