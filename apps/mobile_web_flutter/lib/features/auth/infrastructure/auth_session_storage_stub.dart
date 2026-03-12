import 'auth_session_storage_base.dart';

class _MemoryAuthSessionStorage implements AuthSessionStorage {
  String? _accessToken;

  @override
  Future<String?> readAccessToken() async => _accessToken;

  @override
  Future<void> writeAccessToken(String accessToken) async {
    _accessToken = accessToken;
  }

  @override
  Future<void> clear() async {
    _accessToken = null;
  }
}

AuthSessionStorage createPlatformAuthSessionStorage() {
  return _MemoryAuthSessionStorage();
}
