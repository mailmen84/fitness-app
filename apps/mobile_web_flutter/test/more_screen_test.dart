import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_web_flutter/features/more/domain/more_models.dart';
import 'package:mobile_web_flutter/features/more/infrastructure/more_repository.dart';
import 'package:mobile_web_flutter/features/more/presentation/more_screen.dart';

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

void main() {
  testWidgets('renders the More home with profile, settings, and future modules', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          moreRepositoryProvider.overrideWithValue(_FakeMoreRepository()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: MoreScreen()),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('More & profile'), findsOneWidget);
    expect(find.text('Preview User'), findsNWidgets(2));
    expect(find.text('Cut to 82 kg'), findsOneWidget);
    expect(find.textContaining('Europe/Dublin'), findsOneWidget);
    expect(find.text('PED placeholder'), findsOneWidget);
    expect(find.text('Sign out (preview)'), findsOneWidget);
  });
}
