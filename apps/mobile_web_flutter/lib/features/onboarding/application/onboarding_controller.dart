import 'package:flutter_riverpod/flutter_riverpod.dart';

const Object _unset = Object();

enum OnboardingGoalOption {
  loseWeight,
  buildMuscle,
  maintain,
  improveHabits,
}

extension OnboardingGoalOptionPresentation on OnboardingGoalOption {
  String get title => switch (this) {
        OnboardingGoalOption.loseWeight => 'Lose weight',
        OnboardingGoalOption.buildMuscle => 'Build muscle',
        OnboardingGoalOption.maintain => 'Maintain health',
        OnboardingGoalOption.improveHabits => 'Improve habits',
      };

  String get description => switch (this) {
        OnboardingGoalOption.loseWeight =>
          'Set up a lighter structure with room for weight-loss targets later.',
        OnboardingGoalOption.buildMuscle =>
          'Prepare the account for higher-protein and strength-focused defaults.',
        OnboardingGoalOption.maintain =>
          'Keep a steady baseline while the product foundation stays lightweight.',
        OnboardingGoalOption.improveHabits =>
          'Start with consistency, routines, and day-to-day accountability.',
      };

  String get backendCode => switch (this) {
        OnboardingGoalOption.loseWeight => 'lose_weight',
        OnboardingGoalOption.buildMuscle => 'build_muscle',
        OnboardingGoalOption.maintain => 'maintain_health',
        OnboardingGoalOption.improveHabits => 'improve_habits',
      };
}

enum ActivityLevelOption {
  light,
  moderate,
  active,
  veryActive,
}

extension ActivityLevelOptionPresentation on ActivityLevelOption {
  String get title => switch (this) {
        ActivityLevelOption.light => 'Light',
        ActivityLevelOption.moderate => 'Moderate',
        ActivityLevelOption.active => 'Active',
        ActivityLevelOption.veryActive => 'Very active',
      };

  String get description => switch (this) {
        ActivityLevelOption.light =>
          'Mostly seated days with a small amount of movement.',
        ActivityLevelOption.moderate =>
          'A balanced week with regular walks or training sessions.',
        ActivityLevelOption.active =>
          'Frequent workouts or a physically demanding daily routine.',
        ActivityLevelOption.veryActive =>
          'High training volume or consistently demanding activity.',
      };
}

enum TargetFocusOption {
  consistency,
  bodyComposition,
  performance,
  generalWellbeing,
}

extension TargetFocusOptionPresentation on TargetFocusOption {
  String get title => switch (this) {
        TargetFocusOption.consistency => 'Consistency first',
        TargetFocusOption.bodyComposition => 'Body composition',
        TargetFocusOption.performance => 'Performance',
        TargetFocusOption.generalWellbeing => 'General wellbeing',
      };

  String get description => switch (this) {
        TargetFocusOption.consistency =>
          'Build a repeatable routine before dialing in details.',
        TargetFocusOption.bodyComposition =>
          'Aim for more intentional calorie and physique targets later.',
        TargetFocusOption.performance =>
          'Keep the setup ready for workout-driven goals and metrics.',
        TargetFocusOption.generalWellbeing =>
          'Stay balanced with simple daily guidance and review.',
      };
}

class OnboardingDraft {
  const OnboardingDraft({
    this.email,
    this.displayName,
    this.goal,
    this.age,
    this.heightCm,
    this.startingWeightKg,
    this.activityLevel,
    this.targetFocus,
    this.dailyCalorieTarget,
    this.isCompleted = false,
  });

  final String? email;
  final String? displayName;
  final OnboardingGoalOption? goal;
  final int? age;
  final double? heightCm;
  final double? startingWeightKg;
  final ActivityLevelOption? activityLevel;
  final TargetFocusOption? targetFocus;
  final int? dailyCalorieTarget;
  final bool isCompleted;

  bool get hasGoal => goal != null;

  bool get hasStats =>
      age != null && heightCm != null && startingWeightKg != null;

  bool get hasActivity => activityLevel != null;

  bool get hasTarget => targetFocus != null;

  OnboardingDraft copyWith({
    Object? email = _unset,
    Object? displayName = _unset,
    Object? goal = _unset,
    Object? age = _unset,
    Object? heightCm = _unset,
    Object? startingWeightKg = _unset,
    Object? activityLevel = _unset,
    Object? targetFocus = _unset,
    Object? dailyCalorieTarget = _unset,
    bool? isCompleted,
  }) {
    return OnboardingDraft(
      email: email == _unset ? this.email : email as String?,
      displayName:
          displayName == _unset ? this.displayName : displayName as String?,
      goal: goal == _unset ? this.goal : goal as OnboardingGoalOption?,
      age: age == _unset ? this.age : age as int?,
      heightCm: heightCm == _unset ? this.heightCm : heightCm as double?,
      startingWeightKg: startingWeightKg == _unset
          ? this.startingWeightKg
          : startingWeightKg as double?,
      activityLevel: activityLevel == _unset
          ? this.activityLevel
          : activityLevel as ActivityLevelOption?,
      targetFocus: targetFocus == _unset
          ? this.targetFocus
          : targetFocus as TargetFocusOption?,
      dailyCalorieTarget: dailyCalorieTarget == _unset
          ? this.dailyCalorieTarget
          : dailyCalorieTarget as int?,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class OnboardingController extends Notifier<OnboardingDraft> {
  @override
  OnboardingDraft build() => const OnboardingDraft();

  void seedFromSignup({
    required String email,
    required String displayName,
  }) {
    state = OnboardingDraft(
      email: email.trim(),
      displayName: displayName.trim(),
    );
  }

  void loadReturningMemberPreview({
    required String email,
    String? displayName,
  }) {
    state = OnboardingDraft(
      email: email.trim(),
      displayName: displayName?.trim(),
      isCompleted: true,
    );
  }

  void setGoal(OnboardingGoalOption goal) {
    state = state.copyWith(goal: goal, isCompleted: false);
  }

  void setStats({
    required int age,
    required double heightCm,
    required double startingWeightKg,
  }) {
    state = state.copyWith(
      age: age,
      heightCm: heightCm,
      startingWeightKg: startingWeightKg,
      isCompleted: false,
    );
  }

  void setActivity(ActivityLevelOption activityLevel) {
    state = state.copyWith(activityLevel: activityLevel, isCompleted: false);
  }

  void setTarget({
    required TargetFocusOption targetFocus,
    int? dailyCalorieTarget,
  }) {
    state = state.copyWith(
      targetFocus: targetFocus,
      dailyCalorieTarget: dailyCalorieTarget,
      isCompleted: false,
    );
  }

  void markCompleted() {
    state = state.copyWith(isCompleted: true);
  }

  void reset() {
    state = const OnboardingDraft();
  }
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingDraft>(
  OnboardingController.new,
);