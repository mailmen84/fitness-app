abstract class AuthSessionStorage {
  Future<String?> readAccessToken();
  Future<void> writeAccessToken(String accessToken);
  Future<void> clear();
}
