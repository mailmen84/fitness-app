import 'dart:convert';
import 'dart:io';

import 'auth_session_storage_base.dart';

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
  return _FileAuthSessionStorage();
}
