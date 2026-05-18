import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/widgets/widgets.dart';
import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/validation/form_validators.dart';
import '../../nutrition/application/nutrition_overview_controller.dart';
import '../../onboarding/application/macro_calculator.dart';
import '../../onboarding/application/onboarding_controller.dart';
import '../application/current_user_controller.dart';
import '../application/preferences_controller.dart';
import '../application/preferences_submission_controller.dart';
import '../domain/more_models.dart';
import 'more_presentation_utils.dart';

/// Lets the user (re)compute their daily calorie + protein/carbs/fat targets
/// from height, weight, age, activity level, and primary goal. Saves results
/// to /preferences.
class DietSetupScreen extends ConsumerStatefulWidget {
  const DietSetupScreen({super.key});

  @override
  ConsumerState<DietSetupScreen> createState() => _DietSetupScreenState();
}

class _DietSetupScreenState extends ConsumerState<DietSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  ActivityLevelOption _activity = ActivityLevelOption.moderate;
  OnboardingGoalOption _goal = OnboardingGoalOption.maintain;
  bool _initializedFromUser = false;
  bool _isSubmitting = false;
  String? _submissionError;

  @override
  void initState() {
    super.initState();
    // Seed age + height from the existing user profile once it loads.
    ref.listenManual<AsyncValue<CurrentUserData>>(
      currentUserControllerProvider,
      (previous, next) {
        if (_initializedFromUser) {
          return;
        }
        next.whenData((user) {
          final profile = user.profile;
          if (profile == null) {
            return;
          }
          setState(() {
            if (profile.heightCm != null) {
              _heightController.text = formatMoreNumber(profile.heightCm!);
            }
            final birthDate = profile.birthDate;
            if (birthDate != null) {
              final now = DateTime.now();
              var age = now.year - birthDate.year;
              if (now.month < birthDate.month ||
                  (now.month == birthDate.month && now.day < birthDate.day)) {
                age -= 1;
              }
              if (age > 0) {
                _ageController.text = age.toString();
              }
            }
            _initializedFromUser = true;
          });
        });
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  MacroEstimate? _currentEstimate() {
    final age = int.tryParse(_ageController.text.trim());
    final height = double.tryParse(_heightController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());
    return MacroCalculator.compute(
      age: age,
      heightCm: height,
      weightKg: weight,
      activity: _activity,
      goal: _goal,
    );
  }

  Future<void> _submit(PreferenceData currentPreferences) async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }
    final estimate = _currentEstimate();
    if (estimate == null) {
      setState(() {
        _submissionError = 'Fill in age, height, and weight to compute targets.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });

    try {
      final updated = await ref
          .read(preferencesSubmissionControllerProvider.notifier)
          .submit(
            unitSystem: currentPreferences.unitSystem,
            timezone: currentPreferences.timezone,
            weekStartsOn: currentPreferences.weekStartsOn,
            dailyCalorieTarget: estimate.dailyCalorieTarget,
            dailyProteinTarget: estimate.dailyProteinTarget,
            dailyCarbsTarget: estimate.dailyCarbsTarget,
            dailyFatTarget: estimate.dailyFatTarget,
            onboardingCompleted: currentPreferences.onboardingCompleted,
          );

      if (updated == null) {
        return;
      }

      await ref.read(preferencesControllerProvider.notifier).reload();
      await ref.read(nutritionOverviewControllerProvider.notifier).reload();

      if (!mounted) {
        return;
      }
      context.go(AppRoutePaths.more);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submissionError = moreErrorMessage(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTheme.of(context);
    final preferencesState = ref.watch(preferencesControllerProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: tokens.sectionSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppStandardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diet setup',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Compute your daily calories and macro targets from age, height, weight, activity level, and primary goal. The result is saved to your preferences.',
                  style: theme.textTheme.bodyLarge,
                ),
                SizedBox(height: tokens.sectionSpacing),
                AppSecondaryButton(
                  label: 'Back to more',
                  onPressed: () => context.go(AppRoutePaths.more),
                ),
              ],
            ),
          ),
          SizedBox(height: tokens.sectionSpacing),
          preferencesState.when(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            loading: () => const AppLoadingBlock(
              title: 'Loading preferences',
              message: 'Pulling current targets so we can keep your other settings intact.',
            ),
            error: (error, _) => AppErrorBlock(
              title: 'Could not load preferences',
              message: moreErrorMessage(error),
              action: AppPrimaryButton(
                label: 'Retry',
                expand: true,
                onPressed:
                    ref.read(preferencesControllerProvider.notifier).reload,
              ),
            ),
            data: (value) => _buildForm(context, theme, tokens, value),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    ThemeData theme,
    AppThemeTokens tokens,
    PreferenceData preferences,
  ) {
    final estimate = _currentEstimate();
    final colorScheme = theme.colorScheme;

    return AppStandardCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: 'Age (years)',
              controller: _ageController,
              keyboardType: TextInputType.number,
              validator: (value) => FormValidators.integer(
                value,
                label: 'Age',
                min: 10,
                max: 100,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Height (cm)',
              controller: _heightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) => FormValidators.decimal(
                value,
                label: 'Height',
                min: 100,
                max: 260,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Weight (kg)',
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) => FormValidators.decimal(
                value,
                label: 'Weight',
                min: 30,
                max: 300,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ActivityLevelOption>(
              value: _activity,
              decoration: const InputDecoration(labelText: 'Activity level'),
              items: ActivityLevelOption.values
                  .map(
                    (option) => DropdownMenuItem(
                      value: option,
                      child: Text(option.title),
                    ),
                  )
                  .toList(growable: false),
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _activity = value;
                      });
                    },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<OnboardingGoalOption>(
              value: _goal,
              decoration: const InputDecoration(labelText: 'Primary goal'),
              items: OnboardingGoalOption.values
                  .map(
                    (option) => DropdownMenuItem(
                      value: option,
                      child: Text(option.title),
                    ),
                  )
                  .toList(growable: false),
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _goal = value;
                      });
                    },
            ),
            if (estimate != null) ...[
              SizedBox(height: tokens.sectionSpacing),
              AppStandardCard(
                color: colorScheme.primaryContainer.withOpacity(0.30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Computed daily targets',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'BMR ${estimate.bmr.toStringAsFixed(0)} kcal, TDEE ${estimate.tdee.toStringAsFixed(0)} kcal.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Text('Calories: ${estimate.dailyCalorieTarget.toStringAsFixed(0)} kcal'),
                    const SizedBox(height: 4),
                    Text('Protein: ${estimate.dailyProteinTarget.toStringAsFixed(0)} g'),
                    const SizedBox(height: 4),
                    Text('Carbs: ${estimate.dailyCarbsTarget.toStringAsFixed(0)} g'),
                    const SizedBox(height: 4),
                    Text('Fat: ${estimate.dailyFatTarget.toStringAsFixed(0)} g'),
                  ],
                ),
              ),
            ],
            if (_submissionError != null) ...[
              SizedBox(height: tokens.sectionSpacing),
              AppErrorBlock(
                title: 'Could not save targets',
                message: _submissionError!,
              ),
            ],
            if (_isSubmitting) ...[
              SizedBox(height: tokens.sectionSpacing),
              const AppLoadingBlock(
                title: 'Saving targets',
                message:
                    'Updating preferences and refreshing Nutrition with the new values.',
              ),
            ],
            SizedBox(height: tokens.sectionSpacing),
            AppPrimaryButton(
              label: 'Save targets',
              expand: true,
              onPressed: _isSubmitting ? null : () => _submit(preferences),
            ),
            const SizedBox(height: 12),
            AppSecondaryButton(
              label: 'Cancel',
              expand: true,
              onPressed: _isSubmitting
                  ? null
                  : () => context.go(AppRoutePaths.more),
            ),
          ],
        ),
      ),
    );
  }
}
