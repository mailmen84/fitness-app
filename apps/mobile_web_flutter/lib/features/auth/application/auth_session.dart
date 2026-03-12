import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthSessionState {
  const AuthSessionState({
    this.email,
    this.displayName,
    this.isAuthenticated = false,
    this.hasCompletedOnboarding = false,
  });

  final String? email;
  final String? displayName;
  final bool isAuthenticated;
  final bool hasCompletedOnboarding;

  bool get needsOnboarding => isAuthenticated && !hasCompletedOnboarding;

  AuthSessionState copyWith({
    String? email,
    String? displayName,
    bool? isAuthenticated,
    bool? hasCompletedOnboarding,
  }) {
    return AuthSessionState(
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }
}

class AuthSessionController extends Notifier<AuthSessionState> {
  @override
  AuthSessionState build() => const AuthSessionState();

  String _displayNameFromEmail(String email) {
    final localPart = email.split('@').first.trim();
    if (localPart.isEmpty) {
      return 'Preview User';
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

  void previewLogin({
    required String email,
    bool hasCompletedOnboarding = true,
  }) {
    final trimmedEmail = email.trim();
    state = AuthSessionState(
      email: trimmedEmail,
      displayName: state.displayName ?? _displayNameFromEmail(trimmedEmail),
      isAuthenticated: true,
      hasCompletedOnboarding: hasCompletedOnboarding,
    );
  }

  void previewSignup({
    required String email,
    required String displayName,
  }) {
    state = AuthSessionState(
      email: email.trim(),
      displayName: displayName.trim(),
      isAuthenticated: true,
      hasCompletedOnboarding: false,
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

  void markOnboardingComplete() {
    state = state.copyWith(
      isAuthenticated: true,
      hasCompletedOnboarding: true,
    );
  }

  void signOut() {
    state = const AuthSessionState();
  }
}

// Preview-only local session until real backend auth is wired.
final authSessionProvider =
    NotifierProvider<AuthSessionController, AuthSessionState>(
  AuthSessionController.new,
);