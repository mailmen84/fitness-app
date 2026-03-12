import 'auth_session_storage_base.dart';
import 'auth_session_storage_stub.dart'
    if (dart.library.html) 'auth_session_storage_web.dart'
    if (dart.library.io) 'auth_session_storage_io.dart' as storage_impl;

export 'auth_session_storage_base.dart';

AuthSessionStorage createAuthSessionStorage() {
  return storage_impl.createPlatformAuthSessionStorage();
}
