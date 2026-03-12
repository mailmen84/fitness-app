import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/widgets/widgets.dart';
import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/validation/form_validators.dart';
import '../../nutrition/application/nutrition_overview_controller.dart';
import '../application/preferences_controller.dart';
import '../application/preferences_submission_controller.dart';
import '../domain/more_models.dart';
import 'more_presentation_utils.dart';

class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({super.key});

  @override
  ConsumerState<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _timezoneController = TextEditingController();
  final _dailyCalorieTargetController = TextEditingController();
  final _dailyProteinTargetController = TextEditingController();

  String _unitSystem = 'metric';
  String _weekStartsOn = 'monday';
  bool _initializedForm = false;

  @override
  void dispose() {
    _timezoneController.dispose();
    _dailyCalorieTargetController.dispose();
    _dailyProteinTargetController.dispose();
    super.dispose();
  }

  void _seedForm(PreferenceData preferences) {
    _unitSystem = switch (preferences.unitSystem) {
      'metric' || 'imperial' => preferences.unitSystem,
      _ => 'metric',
    };
    _weekStartsOn = switch (preferences.weekStartsOn) {
      'monday' || 'sunday' => preferences.weekStartsOn,
      _ => 'monday',
    };
    _timezoneController.text = preferences.timezone;
    _dailyCalorieTargetController.text = preferences.dailyCalorieTarget == null
        ? ''
        : formatMoreNumber(preferences.dailyCalorieTarget!);
    _dailyProteinTargetController.text = preferences.dailyProteinTarget == null
        ? ''
        : formatMoreNumber(preferences.dailyProteinTarget!);
    _initializedForm = true;
  }

  Future<void> _submit(PreferenceData currentPreferences) async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final calorieText = _dailyCalorieTargetController.text.trim();
    final proteinText = _dailyProteinTargetController.text.trim();
    final updated = await ref
        .read(preferencesSubmissionControllerProvider.notifier)
        .submit(
          unitSystem: _unitSystem,
          timezone: _timezoneController.text,
          weekStartsOn: _weekStartsOn,
          dailyCalorieTarget:
              calorieText.isEmpty ? null : double.parse(calorieText),
          dailyProteinTarget:
              proteinText.isEmpty ? null : double.parse(proteinText),
          onboardingCompleted: currentPreferences.onboardingCompleted,
        );

    if (!mounted || updated == null) {
      return;
    }

    await ref.read(preferencesControllerProvider.notifier).reload();
    await ref.read(nutritionOverviewControllerProvider.notifier).reload();

    if (!mounted) {
      return;
    }
    context.go(AppRoutePaths.more);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTheme.of(context);
    final preferencesState = ref.watch(preferencesControllerProvider);
    final submissionState = ref.watch(preferencesSubmissionControllerProvider);
    final isSubmitting = submissionState.isLoading;
    final submissionError = switch (submissionState) {
      AsyncError<void>(:final error) => moreErrorMessage(error),
      _ => null,
    };

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
                  'Units & preferences',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage unit system, timezone, week start, and the lightweight daily targets already used by Nutrition.',
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
              message: 'Pulling unit and target settings for editing.',
            ),
            error: (error, _) => AppErrorBlock(
              title: 'Could not load preferences',
              message: moreErrorMessage(error),
              action: AppPrimaryButton(
                label: 'Retry',
                expand: true,
                onPressed: ref
                    .read(preferencesControllerProvider.notifier)
                    .reload,
              ),
            ),
            data: (value) => _buildForm(
              context,
              theme,
              tokens,
              value,
              isSubmitting,
              submissionError,
            ),
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
    bool isSubmitting,
    String? submissionError,
  ) {
    if (!_initializedForm) {
      _seedForm(preferences);
    }

    return AppStandardCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _unitSystem,
              decoration: const InputDecoration(labelText: 'Unit system'),
              items: const [
                DropdownMenuItem(value: 'metric', child: Text('Metric')),
                DropdownMenuItem(value: 'imperial', child: Text('Imperial')),
              ],
              onChanged: isSubmitting
                  ? null
                  : (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _unitSystem = value;
                      });
                    },
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Timezone',
              controller: _timezoneController,
              validator: (value) {
                final normalized = value?.trim() ?? '';
                if (normalized.isEmpty) {
                  return 'Timezone is required.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _weekStartsOn,
              decoration: const InputDecoration(labelText: 'Week starts on'),
              items: const [
                DropdownMenuItem(value: 'monday', child: Text('Monday')),
                DropdownMenuItem(value: 'sunday', child: Text('Sunday')),
              ],
              onChanged: isSubmitting
                  ? null
                  : (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _weekStartsOn = value;
                      });
                    },
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Daily calorie target',
              controller: _dailyCalorieTargetController,
              hintText: 'Optional',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) => FormValidators.optionalDecimal(
                value,
                label: 'Daily calorie target',
                min: 1,
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Daily protein target',
              controller: _dailyProteinTargetController,
              hintText: 'Optional',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) => FormValidators.optionalDecimal(
                value,
                label: 'Daily protein target',
                min: 1,
              ),
            ),
            if (submissionError != null) ...[
              SizedBox(height: tokens.sectionSpacing),
              AppErrorBlock(
                title: 'Could not save preferences',
                message: submissionError,
              ),
            ],
            if (isSubmitting) ...[
              SizedBox(height: tokens.sectionSpacing),
              const AppLoadingBlock(
                title: 'Saving preferences',
                message:
                    'Updating unit settings and daily targets, then refreshing Nutrition state.',
              ),
            ],
            SizedBox(height: tokens.sectionSpacing),
            AppPrimaryButton(
              label: 'Save preferences',
              expand: true,
              onPressed: isSubmitting ? null : () => _submit(preferences),
            ),
            const SizedBox(height: 12),
            AppSecondaryButton(
              label: 'Cancel',
              expand: true,
              onPressed: isSubmitting
                  ? null
                  : () => context.go(AppRoutePaths.more),
            ),
          ],
        ),
      ),
    );
  }
}