import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_session_storage_base.dart';

class _SecureAuthSessionStorage implements AuthSessionStorage {
  static const _accessTokenKey = 'fitness_app_auth_access_token';
  static final FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: const AndroidOptions(encryptedSharedPreferences: true),
    iOptions: const IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  @override
  Future<String?> readAccessToken() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    return accessToken?.trim().isEmpty ?? true ? null : accessToken;
  }

  @override
  Future<void> writeAccessToken(String accessToken) {
    return _storage.write(key: _accessTokenKey, value: accessToken);
  }

  @override
  Future<void> clear() {
    return _storage.delete(key: _accessTokenKey);
  }
}

class _FileAuthSessionStorage implements AuthSessionStorage {
  static const _fileName = 'auth_session.json';

  Directory _baseDirectory() {
    final environment = Platform.environment;
    final root = environment['APPDATA'] ??
        environment['XDG_DATA_HOME'] ??
        environment['HOME'];
    if (root == null || root.trim().isEmpty) {
      return Directory.systemTemp;
    }

    final normalizedRoot = root.endsWith(Platform.pathSeparator)
        ? root.substring(0, root.length - 1)
        : root;
    return Directory(
      '$normalizedRoot${Platform.pathSeparator}fitness-app',
    );
  }

  File _sessionFile() {
    final directory = _baseDirectory();
    return File('${directory.path}${Platform.pathSeparator}$_fileName');
  }

  @override
  Future<String?> readAccessToken() async {
    final file = _sessionFile();
    if (!await file.exists()) {
      return null;
    }

    try {
      final raw = await file.readAsString();
      final payload = jsonDecode(raw) as Map<String, dynamic>;
      final accessToken = payload['access_token'] as String?;
      return accessToken?.trim().isEmpty ?? true ? null : accessToken;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writeAccessToken(String accessToken) async {
    final file = _sessionFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({'access_token': accessToken}),
      flush: true,
    );
  }

  @override
  Future<void> clear() async {
    final file = _sessionFile();
    if (await file.exists()) {
      await file.delete();
    }
  }
}

AuthSessionStorage createPlatformAuthSessionStorage() {
  if (Platform.isAndroid || Platform.isIOS) {
    return _SecureAuthSessionStorage();
  }
  return _FileAuthSessionStorage();
}
