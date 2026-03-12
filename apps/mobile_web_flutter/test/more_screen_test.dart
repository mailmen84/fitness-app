import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_web_flutter/features/more/domain/more_models.dart';
import 'package:mobile_web_flutter/features/more/infrastructure/more_repository.dart';
import 'package:mobile_web_flutter/features/more/presentation/goal_settings_screen.dart';
import 'package:mobile_web_flutter/features/more/presentation/more_screen.dart';
import 'package:mobile_web_flutter/features/more/presentation/preferences_screen.dart';
import 'package:mobile_web_flutter/features/more/presentation/profile_settings_screen.dart';

class _FakeMoreRepository implements MoreRepository {
  @override
  Future<CurrentUserData> fetchCurrentUser() async {
    return CurrentUserData(
      id: 'user-1',
      email: 'preview.user@example.com',
      isActive: true,
      profile: MoreUserProfile(
        displayName: 'Preview User',
        firstName: 'Preview',
        lastName: 'User',
        birthDate: DateTime(1991, 5, 4),
        heightCm: 180.5,
        bio: 'Cutting phase profile',
      ),
    );
  }

  @override
  Future<CurrentUserData> updateCurrentUser({
    required String email,
    String? displayName,
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    double? heightCm,
    String? bio,
  }) async {
    return CurrentUserData(
      id: 'user-1',
      email: email,
      isActive: true,
      profile: MoreUserProfile(
        displayName: displayName,
        firstName: firstName,
        lastName: lastName,
        birthDate: birthDate,
        heightCm: heightCm,
        bio: bio,
      ),
    );
  }

  @override
  Future<CurrentGoalData?> fetchCurrentGoal() async {
    return CurrentGoalData(
      id: 'goal-1',
      code: 'cut',
      title: 'Cut to 82 kg',
      targetValue: 82,
      targetUnit: 'kg',
      startsOn: DateTime(2026, 3, 1),
      endsOn: null,
      notes: 'Stay consistent.',
    );
  }

  @override
  Future<CurrentGoalData> putCurrentGoal({
    required String code,
    required String title,
    double? targetValue,
    String? targetUnit,
    DateTime? startsOn,
    DateTime? endsOn,
    String? notes,
  }) async {
    return CurrentGoalData(
      id: 'goal-1',
      code: code,
      title: title,
      targetValue: targetValue,
      targetUnit: targetUnit,
      startsOn: startsOn,
      endsOn: endsOn,
      notes: notes,
    );
  }

  @override
  Future<PreferenceData> fetchPreferences() async {
    return const PreferenceData(
      id: 'pref-1',
      userId: 'user-1',
      unitSystem: 'metric',
      timezone: 'Europe/Dublin',
      weekStartsOn: 'monday',
      dailyCalorieTarget: 2200,
      dailyProteinTarget: 165,
      onboardingCompleted: true,
    );
  }

  @override
  Future<PreferenceData> putPreferences({
    required String unitSystem,
    required String timezone,
    required String weekStartsOn,
    double? dailyCalorieTarget,
    double? dailyProteinTarget,
    required bool onboardingCompleted,
  }) async {
    return PreferenceData(
      id: 'pref-1',
      userId: 'user-1',
      unitSystem: unitSystem,
      timezone: timezone,
      weekStartsOn: weekStartsOn,
      dailyCalorieTarget: dailyCalorieTarget,
      dailyProteinTarget: dailyProteinTarget,
      onboardingCompleted: onboardingCompleted,
    );
  }
}

TextFormField _textFormField(WidgetTester tester, String label) {
  return tester.widget<TextFormField>(
    find.byWidgetPredicate(
      (widget) =>
          widget is TextFormField && widget.decoration?.labelText == label,
      description: 'TextFormField($label)',
    ),
  );
}

Future<void> _pumpMoreScreen(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        moreRepositoryProvider.overrideWithValue(_FakeMoreRepository()),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  testWidgets('renders the More home with profile, settings, and future modules', (
    tester,
  ) async {
    await _pumpMoreScreen(tester, const MoreScreen());

    expect(find.text('More & settings'), findsOneWidget);
    expect(find.text('Preview User'), findsNWidgets(2));
    expect(find.text('Cut to 82 kg'), findsOneWidget);
    expect(find.textContaining('Europe/Dublin'), findsOneWidget);
    expect(find.text('PED placeholder'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('profile settings seed the loaded profile values without exceptions', (
    tester,
  ) async {
    await _pumpMoreScreen(tester, const ProfileSettingsScreen());

    expect(tester.takeException(), isNull);
    expect(_textFormField(tester, 'Email').controller?.text, 'preview.user@example.com');
    expect(_textFormField(tester, 'Display name').controller?.text, 'Preview User');
    expect(_textFormField(tester, 'Height (cm)').controller?.text, '180.5');
    expect(_textFormField(tester, 'Bio').controller?.text, 'Cutting phase profile');
  });

  testWidgets('goal settings seed the loaded goal values without exceptions', (
    tester,
  ) async {
    await _pumpMoreScreen(tester, const GoalSettingsScreen());

    expect(tester.takeException(), isNull);
    expect(_textFormField(tester, 'Goal title').controller?.text, 'Cut to 82 kg');
    expect(_textFormField(tester, 'Target value').controller?.text, '82');
    expect(_textFormField(tester, 'Notes').controller?.text, 'Stay consistent.');
  });

  testWidgets('preferences screen seeds the loaded values without exceptions', (
    tester,
  ) async {
    await _pumpMoreScreen(tester, const PreferencesScreen());

    expect(tester.takeException(), isNull);
    expect(_textFormField(tester, 'Timezone').controller?.text, 'Europe/Dublin');
    expect(_textFormField(tester, 'Daily calorie target').controller?.text, '2200');
    expect(_textFormField(tester, 'Daily protein target').controller?.text, '165');
  });
}

