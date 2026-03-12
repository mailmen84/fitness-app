import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_web_flutter/core/theme/app_theme.dart';
import 'package:mobile_web_flutter/features/auth/presentation/password_reset_screen.dart';

void main() {
  testWidgets('renders password reset guidance and actions', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const PasswordResetScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Password reset'), findsOneWidget);
    expect(find.text('Recover account access'), findsOneWidget);
    expect(find.text('Request reset token'), findsOneWidget);
    expect(find.text('Back to login'), findsOneWidget);
  });
}
