import 'onboarding_controller.dart';

/// Biological sex used in the BMR formula. The onboarding wizard does not yet
/// ask for it explicitly, so we keep the calculator open to receive it later
/// while defaulting to a neutral male estimate (the most common case for the
/// initial user). All consumers may override it.
enum BiologicalSex { male, female }

/// Output of [MacroCalculator.compute].
class MacroEstimate {
  const MacroEstimate({
    required this.bmr,
    required this.tdee,
    required this.dailyCalorieTarget,
    required this.dailyProteinTarget,
    required this.dailyCarbsTarget,
    required this.dailyFatTarget,
  });

  /// Basal metabolic rate (kcal/day), Mifflin-St Jeor.
  final double bmr;

  /// Total daily energy expenditure (kcal/day) after activity multiplier.
  final double tdee;

  /// Suggested daily calorie target after goal adjustment.
  final double dailyCalorieTarget;

  /// Suggested daily protein target (grams).
  final double dailyProteinTarget;

  /// Suggested daily carbs target (grams).
  final double dailyCarbsTarget;

  /// Suggested daily fat target (grams).
  final double dailyFatTarget;
}

class MacroCalculator {
  const MacroCalculator._();

  /// Compute a full macro recommendation from onboarding inputs.
  ///
  /// Returns `null` when required inputs are missing (age, height, weight, or
  /// activity level), so callers can keep the controls disabled.
  static MacroEstimate? compute({
    required int? age,
    required double? heightCm,
    required double? weightKg,
    required ActivityLevelOption? activity,
    required OnboardingGoalOption? goal,
    BiologicalSex sex = BiologicalSex.male,
  }) {
    if (age == null || heightCm == null || weightKg == null) {
      return null;
    }
    if (activity == null) {
      return null;
    }
    if (age <= 0 || heightCm <= 0 || weightKg <= 0) {
      return null;
    }

    // Mifflin-St Jeor.
    final bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) +
        (sex == BiologicalSex.male ? 5 : -161);

    final tdee = bmr * _activityMultiplier(activity);

    final dailyCalorieTarget = tdee * _goalCalorieRatio(goal);

    // Macro split: protein anchored at 2 g/kg lean weight (use bodyweight as a
    // simple proxy), fat at 25% of calories, carbs fill the remainder.
    final dailyProteinTarget = (weightKg * 2.0).clamp(50, 250).toDouble();
    final dailyFatTarget = (dailyCalorieTarget * 0.25) / 9;
    final proteinKcal = dailyProteinTarget * 4;
    final fatKcal = dailyFatTarget * 9;
    final carbsKcal = (dailyCalorieTarget - proteinKcal - fatKcal)
        .clamp(0, double.infinity)
        .toDouble();
    final dailyCarbsTarget = carbsKcal / 4;

    return MacroEstimate(
      bmr: _round(bmr),
      tdee: _round(tdee),
      dailyCalorieTarget: _round(dailyCalorieTarget),
      dailyProteinTarget: _round(dailyProteinTarget),
      dailyCarbsTarget: _round(dailyCarbsTarget),
      dailyFatTarget: _round(dailyFatTarget),
    );
  }

  static double _activityMultiplier(ActivityLevelOption activity) {
    return switch (activity) {
      ActivityLevelOption.light => 1.375,
      ActivityLevelOption.moderate => 1.55,
      ActivityLevelOption.active => 1.725,
      ActivityLevelOption.veryActive => 1.9,
    };
  }

  static double _goalCalorieRatio(OnboardingGoalOption? goal) {
    return switch (goal) {
      OnboardingGoalOption.loseWeight => 0.8,
      OnboardingGoalOption.buildMuscle => 1.1,
      OnboardingGoalOption.maintain => 1.0,
      OnboardingGoalOption.improveHabits => 1.0,
      null => 1.0,
    };
  }

  static double _round(double value) {
    return double.parse(value.toStringAsFixed(0));
  }
}
