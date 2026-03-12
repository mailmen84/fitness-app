import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/app_api_client.dart';
import '../../../core/presentation/widgets/widgets.dart';
import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/validation/form_validators.dart';
import '../../auth/application/auth_session.dart';
import '../application/onboarding_controller.dart';

class OnboardingTargetScreen extends ConsumerStatefulWidget {
  const OnboardingTargetScreen({super.key});

  @override
  ConsumerState<OnboardingTargetScreen> createState() =>
      _OnboardingTargetScreenState();
}

class _OnboardingTargetScreenState extends ConsumerState<OnboardingTargetScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dailyCalorieTargetController;
  bool _showSelectionError = false;
  bool _isSubmitting = false;
  String? _submissionError;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(onboardingControllerProvider);
    _dailyCalorieTargetController = TextEditingController(
      text: draft.dailyCalorieTarget?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _dailyCalorieTargetController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final draft = ref.read(onboardingControllerProvider);
    if (!draft.hasTarget) {
      setState(() => _showSelectionError = true);
      return;
    }

    final calorieTargetText = _dailyCalorieTargetController.text.trim();
    final dailyCalorieTarget =
        calorieTargetText.isEmpty ? null : int.parse(calorieTargetText);

    setState(() {
      _isSubmitting = true;
      _submissionError = null;
      _showSelectionError = false;
    });

    try {
      ref.read(onboardingControllerProvider.notifier).setTarget(
            targetFocus: draft.targetFocus!,
            dailyCalorieTarget: dailyCalorieTarget,
          );
      await ref.read(authSessionProvider.notifier).completeOnboarding(
            dailyCalorieTarget: dailyCalorieTarget,
          );
      ref.read(onboardingControllerProvider.notifier).markCompleted();

      if (!mounted) {
        return;
      }
      context.go(AppRoutePaths.today);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submissionError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submissionError =
            'Could not finish onboarding right now. Please try again.';
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
    final draft = ref.watch(onboardingControllerProvider);
    final colorScheme = theme.colorScheme;

    return AppScaffold(
      appBar: const AppTopAppBar(title: 'Onboarding Target'),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppStandardCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step 4 of 4',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Choose the target you want the app to lean toward first',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Finish onboarding by selecting a target emphasis and an optional daily calorie target.',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              if (_showSelectionError) ...[
                SizedBox(height: tokens.sectionSpacing),
                const AppErrorBlock(
                  title: 'Choose a target focus',
                  message:
                      'Select one target direction before finishing onboarding.',
                ),
              ],
              if (_submissionError != null) ...[
                SizedBox(height: tokens.sectionSpacing),
                AppErrorBlock(
                  title: 'Could not finish onboarding',
                  message: _submissionError!,
                ),
              ],
              for (final option in TargetFocusOption.values) ...[
                SizedBox(height: tokens.sectionSpacing),
                AppStandardCard(
                  color: draft.targetFocus == option
                      ? colorScheme.secondaryContainer.withOpacity(0.45)
                      : null,
                  child: RadioListTile<TargetFocusOption>(
                    value: option,
                    groupValue: draft.targetFocus,
                    contentPadding: EdgeInsets.zero,
                    title: Text(option.title),
                    subtitle: Text(option.description),
                    onChanged: _isSubmitting
                        ? null
                        : (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() => _showSelectionError = false);
                            ref.read(onboardingControllerProvider.notifier).setTarget(
                                  targetFocus: value,
                                  dailyCalorieTarget: draft.dailyCalorieTarget,
                                );
                          },
                  ),
                ),
              ],
              SizedBox(height: tokens.sectionSpacing),
              AppStandardCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Optional target',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Daily calorie target (optional)',
                      hintText: '2100',
                      controller: _dailyCalorieTargetController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      validator: (value) => FormValidators.optionalInteger(
                        value,
                        label: 'Daily calorie target',
                        min: 1000,
                        max: 5000,
                      ),
                      onFieldSubmitted: (_) => _complete(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: tokens.sectionSpacing),
              AppStandardCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Onboarding summary',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Goal: ${draft.goal?.title ?? 'Not selected'}'),
                    const SizedBox(height: 8),
                    Text(
                      'Stats: ${draft.age ?? '-'} years, ${draft.heightCm ?? '-'} cm, ${draft.startingWeightKg ?? '-'} kg',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Activity: ${draft.activityLevel?.title ?? 'Not selected'}',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Target: ${draft.targetFocus?.title ?? 'Not selected'}',
                    ),
                  ],
                ),
              ),
              if (_isSubmitting) ...[
                SizedBox(height: tokens.sectionSpacing),
                const AppLoadingBlock(
                  title: 'Finalizing onboarding',
                  message:
                      'Saving the onboarding-complete flag for your account and opening Today.',
                ),
              ],
              SizedBox(height: tokens.sectionSpacing),
              AppPrimaryButton(
                label: 'Finish onboarding',
                expand: true,
                onPressed: _isSubmitting ? null : _complete,
              ),
              const SizedBox(height: 12),
              AppSecondaryButton(
                label: 'Back to activity',
                expand: true,
                onPressed: _isSubmitting
                    ? null
                    : () => context.go(AppRoutePaths.onboardingActivity),
              ),
              SizedBox(height: tokens.sectionSpacing),
              const AppEmptyStateBlock(
                title: 'Your account stays signed in',
                message:
                    'Finishing onboarding now also marks the authenticated account as onboarding-complete for future logins.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
