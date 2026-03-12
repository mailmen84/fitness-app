import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/widgets/widgets.dart';
import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../application/onboarding_controller.dart';

class OnboardingActivityScreen extends ConsumerStatefulWidget {
  const OnboardingActivityScreen({super.key});

  @override
  ConsumerState<OnboardingActivityScreen> createState() =>
      _OnboardingActivityScreenState();
}

class _OnboardingActivityScreenState
    extends ConsumerState<OnboardingActivityScreen> {
  bool _showSelectionError = false;

  void _continue() {
    final draft = ref.read(onboardingControllerProvider);
    if (!draft.hasActivity) {
      setState(() => _showSelectionError = true);
      return;
    }

    context.go(AppRoutePaths.onboardingTarget);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTheme.of(context);
    final draft = ref.watch(onboardingControllerProvider);
    final colorScheme = theme.colorScheme;

    return AppScaffold(
      appBar: const AppTopAppBar(title: 'Onboarding Activity'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppStandardCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step 3 of 4',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'How active does your normal week feel?',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Keep this high-level so onboarding stays quick while the rest of the MVP remains simple and predictable.',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            if (_showSelectionError) ...[
              SizedBox(height: tokens.sectionSpacing),
              const AppErrorBlock(
                title: 'Select an activity level',
                message:
                    'Choose one option before moving to the target setup step.',
              ),
            ],
            for (final option in ActivityLevelOption.values) ...[
              SizedBox(height: tokens.sectionSpacing),
              AppStandardCard(
                color: draft.activityLevel == option
                    ? colorScheme.secondaryContainer.withOpacity(0.45)
                    : null,
                child: RadioListTile<ActivityLevelOption>(
                  value: option,
                  groupValue: draft.activityLevel,
                  contentPadding: EdgeInsets.zero,
                  title: Text(option.title),
                  subtitle: Text(option.description),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _showSelectionError = false);
                    ref
                        .read(onboardingControllerProvider.notifier)
                        .setActivity(value);
                  },
                ),
              ),
            ],
            SizedBox(height: tokens.sectionSpacing),
            AppPrimaryButton(
              label: 'Next: Target',
              expand: true,
              onPressed: _continue,
            ),
            const SizedBox(height: 12),
            AppSecondaryButton(
              label: 'Back to stats',
              expand: true,
              onPressed: () => context.go(AppRoutePaths.onboardingStats),
            ),
            SizedBox(height: tokens.sectionSpacing),
            const AppEmptyStateBlock(
              title: 'Recommendations stay deferred',
              message:
                  'No calorie math or adaptive coaching runs yet. This step only captures structure for later use.',
            ),
          ],
        ),
      ),
    );
  }
}
