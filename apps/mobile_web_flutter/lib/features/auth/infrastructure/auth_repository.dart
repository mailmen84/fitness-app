import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/environment.dart';
import '../../../core/network/app_api_client.dart';
import '../domain/auth_models.dart';
import 'auth_session_storage.dart';

abstract class AuthRepository {
  Future<AuthTokenBundle> signup({
    required String displayName,
    required String email,
    required String password,
  });

  Future<AuthTokenBundle> login({
    required String email,
    required String password,
  });

  Future<AuthChallengeData> requestPasswordReset({
    required String email,
  });

  Future<AuthTokenBundle> confirmPasswordReset({
    required String token,
    required String newPassword,
  });

  Future<AuthSessionData> restoreSession(String accessToken);

  Future<void> completeOnboarding({
    required String accessToken,
    int? dailyCalorieTarget,
    double? dailyProteinTarget,
    double? dailyCarbsTarget,
    double? dailyFatTarget,
  });

  Future<String?> readStoredAccessToken();
  Future<void> persistAccessToken(String accessToken);
  Future<void> clearStoredAccessToken();
}

class ApiAuthRepository implements AuthRepository {
  const ApiAuthRepository({
    required this.baseUrl,
    required this.storage,
  });

  final String baseUrl;
  final AuthSessionStorage storage;

  AppApiClient get _client => AppApiClient(baseUrl: baseUrl);

  AppApiClient _authorizedClient(String accessToken) {
    return AppApiClient(
      baseUrl: baseUrl,
      accessToken: accessToken,
    );
  }

  @override
  Future<AuthTokenBundle> signup({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final payload = await _client.postJsonMap(
      '/auth/signup',
      body: {
        'display_name': displayName.trim(),
        'email': email.trim(),
        'password': password,
      },
    );
    return AuthTokenBundle.fromJson(payload);
  }

  @override
  Future<AuthTokenBundle> login({
    required String email,
    required String password,
  }) async {
    final payload = await _client.postJsonMap(
      '/auth/login',
      body: {
        'email': email.trim(),
        'password': password,
      },
    );
    return AuthTokenBundle.fromJson(payload);
  }

  @override
  Future<AuthChallengeData> requestPasswordReset({
    required String email,
  }) async {
    final payload = await _client.postJsonMap(
      '/auth/password-reset/request',
      body: {
        'email': email.trim(),
      },
    );
    return AuthChallengeData.fromJson(payload);
  }

  @override
  Future<AuthTokenBundle> confirmPasswordReset({
    required String token,
    required String newPassword,
  }) async {
    final payload = await _client.postJsonMap(
      '/auth/password-reset/confirm',
      body: {
        'token': token.trim(),
        'new_password': newPassword,
      },
    );
    return AuthTokenBundle.fromJson(payload);
  }

  @override
  Future<AuthSessionData> restoreSession(String accessToken) async {
    final payload = await _authorizedClient(accessToken).getMap('/auth/session');
    return AuthSessionData.fromJson(payload);
  }

  @override
  Future<void> completeOnboarding({
    required String accessToken,
    int? dailyCalorieTarget,
    double? dailyProteinTarget,
    double? dailyCarbsTarget,
    double? dailyFatTarget,
  }) async {
    final client = _authorizedClient(accessToken);
    final currentPreferences = await client.getMap('/preferences');
    await client.putJsonMap(
      '/preferences',
      body: {
        'unit_system': currentPreferences['unit_system'] ?? 'metric',
        'timezone': currentPreferences['timezone'] ?? 'UTC',
        'week_starts_on': currentPreferences['week_starts_on'] ?? 'monday',
        'daily_calorie_target':
            dailyCalorieTarget ?? currentPreferences['daily_calorie_target'],
        'daily_protein_target':
            dailyProteinTarget ?? currentPreferences['daily_protein_target'],
        'daily_carbs_target':
            dailyCarbsTarget ?? currentPreferences['daily_carbs_target'],
        'daily_fat_target':
            dailyFatTarget ?? currentPreferences['daily_fat_target'],
        'onboarding_completed': true,
      },
    );
  }

  @override
  Future<String?> readStoredAccessToken() {
    return storage.readAccessToken();
  }

  @override
  Future<void> persistAccessToken(String accessToken) {
    return storage.writeAccessToken(accessToken);
  }

  @override
  Future<void> clearStoredAccessToken() {
    return storage.clear();
  }
}

final authSessionStorageProvider = Provider<AuthSessionStorage>((ref) {
  return createAuthSessionStorage();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final storage = ref.watch(authSessionStorageProvider);
  return ApiAuthRepository(
    baseUrl: Environment.defaultApiBaseUrl,
    storage: storage,
  );
});
