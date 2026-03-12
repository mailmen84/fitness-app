import 'dart:html' as html;

import 'auth_session_storage_base.dart';

class _WebAuthSessionStorage implements AuthSessionStorage {
  static const _accessTokenKey = 'fitness_app_auth_access_token';

  @override
  Future<String?> readAccessToken() async {
    final accessToken = html.window.localStorage[_accessTokenKey];
    return accessToken?.trim().isEmpty ?? true ? null : accessToken;
  }

  @override
  Future<void> writeAccessToken(String accessToken) async {
    html.window.localStorage[_accessTokenKey] = accessToken;
  }

  @override
  Future<void> clear() async {
    html.window.localStorage.remove(_accessTokenKey);
  }
}

AuthSessionStorage createPlatformAuthSessionStorage() {
  return _WebAuthSessionStorage();
}
