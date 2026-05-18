import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_models.dart';
import '../infrastructure/auth_repository.dart';

const Object _unset = Object();

class AuthSessionState {
  const AuthSessionState({
    this.accessToken,
    this.email,
    this.displayName,
    this.emailVerified = false,
    this.isAuthenticated = false,
    this.hasCompletedOnboarding = false,
    this.isHydrating = true,
  });

  final String? accessToken;
  final String? email;
  final String? displayName;
  final bool emailVerified;
  final bool isAuthenticated;
  final bool hasCompletedOnboarding;
  final bool isHydrating;

  bool get needsOnboarding => isAuthenticated && !hasCompletedOnboarding;

  AuthSessionState copyWith({
    Object? accessToken = _unset,
    Object? email = _unset,
    Object? displayName = _unset,
    bool? emailVerified,
    bool? isAuthenticated,
    bool? hasCompletedOnboarding,
    bool? isHydrating,
  }) {
    return AuthSessionState(
      accessToken:
          accessToken == _unset ? this.accessToken : accessToken as String?,
      email: email == _unset ? this.email : email as String?,
      displayName:
          displayName == _unset ? this.displayName : displayName as String?,
      emailVerified: emailVerified ?? this.emailVerified,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      isHydrating: isHydrating ?? this.isHydrating,
    );
  }
}

class AuthSessionController extends Notifier<AuthSessionState> {
  late final AuthRepository _repository;
  bool _hasScheduledHydration = false;

  String _displayNameFromEmail(String email) {
    final localPart = email.split('@').first.trim();
    if (localPart.isEmpty) {
      return 'User';
    }

    return localPart
        .split(RegExp(r'[._-]+'))
        .where((segment) => segment.isNotEmpty)
        .map(
          (segment) =>
              '${segment[0].toUpperCase()}${segment.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  @override
  AuthSessionState build() {
    _repository = ref.watch(authRepositoryProvider);
    if (!_hasScheduledHydration) {
      _hasScheduledHydration = true;
      Future<void>.microtask(_hydrateSession);
      return const AuthSessionState();
    }
    return state;
  }

  AuthSessionState _stateFromSession(
    AuthSessionData session, {
    required String accessToken,
  }) {
    return AuthSessionState(
      accessToken: accessToken,
      email: session.email,
      displayName: session.resolvedDisplayName,
      emailVerified: session.emailVerified,
      isAuthenticated: true,
      hasCompletedOnboarding: session.onboardingCompleted,
      isHydrating: false,
    );
  }

  Future<void> _hydrateSession() async {
    final storedAccessToken = await _repository.readStoredAccessToken();
    if (storedAccessToken == null || storedAccessToken.trim().isEmpty) {
      state = const AuthSessionState(isHydrating: false);
      return;
    }

    try {
      final session = await _repository.restoreSession(storedAccessToken);
      state = _stateFromSession(
        session,
        accessToken: storedAccessToken,
      );
    } catch (_) {
      await _repository.clearStoredAccessToken();
      state = const AuthSessionState(isHydrating: false);
    }
  }

  Future<AuthSessionState> login({
    required String email,
    required String password,
  }) async {
    final response = await _repository.login(
      email: email,
      password: password,
    );
    await _repository.persistAccessToken(response.accessToken);
    final nextState = _stateFromSession(
      response.session,
      accessToken: response.accessToken,
    );
    state = nextState;
    return nextState;
  }

  Future<AuthSessionState> signup({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final response = await _repository.signup(
      displayName: displayName,
      email: email,
      password: password,
    );
    await _repository.persistAccessToken(response.accessToken);
    final nextState = _stateFromSession(
      response.session,
      accessToken: response.accessToken,
    );
    state = nextState;
    return nextState;
  }

  Future<AuthChallengeData> requestPasswordReset({
    required String email,
  }) {
    return _repository.requestPasswordReset(email: email);
  }

  Future<AuthSessionState> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final response = await _repository.confirmPasswordReset(
      token: token,
      newPassword: newPassword,
    );
    await _repository.persistAccessToken(response.accessToken);
    final nextState = _stateFromSession(
      response.session,
      accessToken: response.accessToken,
    );
    state = nextState;
    return nextState;
  }

  Future<void> completeOnboarding({
    int? dailyCalorieTarget,
    double? dailyProteinTarget,
    double? dailyCarbsTarget,
    double? dailyFatTarget,
  }) async {
    final accessToken = state.accessToken;
    if (accessToken == null || accessToken.trim().isEmpty) {
      return;
    }

    await _repository.completeOnboarding(
      accessToken: accessToken,
      dailyCalorieTarget: dailyCalorieTarget,
      dailyProteinTarget: dailyProteinTarget,
      dailyCarbsTarget: dailyCarbsTarget,
      dailyFatTarget: dailyFatTarget,
    );
    state = state.copyWith(
      hasCompletedOnboarding: true,
      isAuthenticated: true,
      isHydrating: false,
    );
  }

  void syncProfile({
    required String email,
    String? displayName,
  }) {
    if (!state.isAuthenticated) {
      return;
    }

    final trimmedEmail = email.trim();
    final trimmedDisplayName = displayName?.trim() ?? '';
    state = state.copyWith(
      email: trimmedEmail,
      displayName: trimmedDisplayName.isEmpty
          ? _displayNameFromEmail(trimmedEmail)
          : trimmedDisplayName,
    );
  }

  Future<void> signOut() async {
    await _repository.clearStoredAccessToken();
    state = const AuthSessionState(isHydrating: false);
  }
}

final authSessionProvider =
    NotifierProvider<AuthSessionController, AuthSessionState>(
  AuthSessionController.new,
);
