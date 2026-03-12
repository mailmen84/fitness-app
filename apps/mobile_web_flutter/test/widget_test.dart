import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_web_flutter/app/app.dart';

void main() {
  testWidgets('renders the authenticated welcome screen entry point', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FitnessApp()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Fitness App'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });
}
