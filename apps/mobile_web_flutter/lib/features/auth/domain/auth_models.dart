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

class AuthSessionData {
  const AuthSessionData({
    required this.email,
    required this.displayName,
    required this.onboardingCompleted,
  });

  final String email;
  final String? displayName;
  final bool onboardingCompleted;

  String get resolvedDisplayName {
    final trimmedDisplayName = displayName?.trim() ?? '';
    return trimmedDisplayName.isEmpty
        ? _displayNameFromEmail(email)
        : trimmedDisplayName;
  }

  factory AuthSessionData.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>? ?? const {};
    final profileJson = userJson['profile'] as Map<String, dynamic>? ?? const {};
    return AuthSessionData(
      email: userJson['email'] as String? ?? '',
      displayName: profileJson['display_name'] as String?,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
    );
  }
}

class AuthTokenBundle {
  const AuthTokenBundle({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.session,
  });

  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final AuthSessionData session;

  factory AuthTokenBundle.fromJson(Map<String, dynamic> json) {
    return AuthTokenBundle(
      accessToken: json['access_token'] as String? ?? '',
      tokenType: json['token_type'] as String? ?? 'bearer',
      expiresIn: json['expires_in'] as int? ?? 0,
      session: AuthSessionData.fromJson(
        json['session'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
