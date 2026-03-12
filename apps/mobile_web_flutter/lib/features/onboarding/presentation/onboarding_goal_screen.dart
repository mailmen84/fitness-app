import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/widgets/widgets.dart';
import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../application/onboarding_controller.dart';

class OnboardingGoalScreen extends ConsumerStatefulWidget {
  const OnboardingGoalScreen({super.key});

  @override
  ConsumerState<OnboardingGoalScreen> createState() => _OnboardingGoalScreenState();
}

class _OnboardingGoalScreenState extends ConsumerState<OnboardingGoalScreen> {
  bool _showSelectionError = false;

  void _continue() {
    final draft = ref.read(onboardingControllerProvider);
    if (!draft.hasGoal) {
      setState(() => _showSelectionError = true);
      return;
    }

    context.go(AppRoutePaths.onboardingStats);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTheme.of(context);
    final draft = ref.watch(onboardingControllerProvider);
    final colorScheme = theme.colorScheme;

    return AppScaffold(
      appBar: const AppTopAppBar(title: 'Onboarding Goal'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppStandardCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step 1 of 4',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    draft.displayName == null
                        ? 'What is your main focus?'
                        : 'What should ${draft.displayName} focus on first?',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Choose the high-level goal you want this foundation to carry into later backend persistence and dashboard work.',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            if (_showSelectionError) ...[
              SizedBox(height: tokens.sectionSpacing),
              const AppErrorBlock(
                title: 'Choose a goal first',
                message:
                    'Select one foundation goal before moving to the stats step.',
              ),
            ],
            for (final option in OnboardingGoalOption.values) ...[
              SizedBox(height: tokens.sectionSpacing),
              AppStandardCard(
                color: draft.goal == option
                    ? colorScheme.secondaryContainer.withOpacity(0.45)
                    : null,
                child: RadioListTile<OnboardingGoalOption>(
                  value: option,
                  groupValue: draft.goal,
                  contentPadding: EdgeInsets.zero,
                  title: Text(option.title),
                  subtitle: Text(option.description),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _showSelectionError = false);
                    ref.read(onboardingControllerProvider.notifier).setGoal(value);
                  },
                ),
              ),
            ],
            SizedBox(height: tokens.sectionSpacing),
            AppPrimaryButton(
              label: 'Next: Stats',
              expand: true,
              onPressed: _continue,
            ),
            const SizedBox(height: 12),
            AppSecondaryButton(
              label: 'Back to signup',
              expand: true,
              onPressed: () => context.go(AppRoutePaths.signup),
            ),
            SizedBox(height: tokens.sectionSpacing),
            const AppEmptyStateBlock(
              title: 'Saved locally for now',
              message:
                  'Goal selection lives in Riverpod state in this milestone. The backend goal API foundation is ready, but frontend sync stays deferred.',
            ),
          ],
        ),
      ),
    );
  }
}