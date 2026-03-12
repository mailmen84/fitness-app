import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/environment.dart';
import '../../../core/network/app_api_client.dart';
import '../../auth/application/auth_session.dart';

final appApiClientProvider = Provider<AppApiClient>((ref) {
  final authSession = ref.watch(authSessionProvider);
  return AppApiClient(
    baseUrl: Environment.defaultApiBaseUrl,
    accessToken: authSession.accessToken,
  );
});
