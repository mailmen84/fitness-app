import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_web_flutter/app/app.dart';

void main() {
  testWidgets('renders scaffold message', (tester) async {
    await tester.pumpWidget(const FitnessApp());

    expect(find.text('Monorepo scaffold ready'), findsOneWidget);
    expect(find.text('Fitness App'), findsOneWidget);
  });
}

