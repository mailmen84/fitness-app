import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_web_flutter/app/app.dart';

void main() {
  testWidgets('renders the authentication-ready welcome screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FitnessApp()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Authentication-ready shell'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });
}