import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/widgets/widgets.dart';
import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/validation/form_validators.dart';
import '../application/onboarding_controller.dart';

class OnboardingStatsScreen extends ConsumerStatefulWidget {
  const OnboardingStatsScreen({super.key});

  @override
  ConsumerState<OnboardingStatsScreen> createState() => _OnboardingStatsScreenState();
}

class _OnboardingStatsScreenState extends ConsumerState<OnboardingStatsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(onboardingControllerProvider);
    _ageController = TextEditingController(
      text: draft.age == null ? '' : draft.age.toString(),
    );
    _heightController = TextEditingController(
      text: _formatNumber(draft.heightCm),
    );
    _weightController = TextEditingController(
      text: _formatNumber(draft.startingWeightKg),
    );
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  String _formatNumber(double? value) {
    if (value == null) {
      return '';
    }
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    ref.read(onboardingControllerProvider.notifier).setStats(
          age: int.parse(_ageController.text.trim()),
          heightCm: double.parse(_heightController.text.trim()),
          startingWeightKg: double.parse(_weightController.text.trim()),
        );

    context.go(AppRoutePaths.onboardingActivity);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTheme.of(context);
    final draft = ref.watch(onboardingControllerProvider);
    final firstName = draft.displayName?.split(' ').first;

    return AppScaffold(
      appBar: const AppTopAppBar(title: 'Onboarding Stats'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppStandardCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step 2 of 4',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    firstName == null
                        ? 'Add a few baseline stats'
                        : 'Add a few baseline stats for $firstName',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Keep this lightweight. The goal is just enough structure to personalize the authenticated MVP without making onboarding heavy.',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            SizedBox(height: tokens.sectionSpacing),
            AppStandardCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      label: 'Age',
                      hintText: '29',
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: (value) => FormValidators.integer(
                        value,
                        label: 'Age',
                        min: 13,
                        max: 100,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Height (cm)',
                      hintText: '175',
                      controller: _heightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) => FormValidators.decimal(
                        value,
                        label: 'Height',
                        min: 100,
                        max: 250,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Starting weight (kg)',
                      hintText: '74.5',
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.done,
                      validator: (value) => FormValidators.decimal(
                        value,
                        label: 'Starting weight',
                        min: 35,
                        max: 300,
                      ),
                      onFieldSubmitted: (_) => _continue(),
                    ),
                    const SizedBox(height: 24),
                    AppPrimaryButton(
                      label: 'Next: Activity',
                      expand: true,
                      onPressed: _continue,
                    ),
                    const SizedBox(height: 12),
                    AppSecondaryButton(
                      label: 'Back to goal',
                      expand: true,
                      onPressed: () => context.go(AppRoutePaths.onboardingGoal),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: tokens.sectionSpacing),
            const AppEmptyStateBlock(
              title: 'Baseline stats only',
              message:
                  'Unit preferences and richer profile editing can grow from here later. This step keeps the onboarding draft clean and minimal for now.',
            ),
          ],
        ),
      ),
    );
  }
}
