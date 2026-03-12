import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/environment.dart';
import '../../../core/presentation/widgets/widgets.dart';
import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../../onboarding/application/onboarding_controller.dart';
import '../application/auth_session.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  Future<void> _signOut(WidgetRef ref) async {
    await ref.read(authSessionProvider.notifier).signOut();
    ref.read(onboardingControllerProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = AppTheme.of(context);
    final session = ref.watch(authSessionProvider);
    final onboardingDraft = ref.watch(onboardingControllerProvider);
    final completedSteps = [
      onboardingDraft.hasGoal,
      onboardingDraft.hasStats,
      onboardingDraft.hasActivity,
      onboardingDraft.hasTarget,
    ].where((step) => step).length;

    final subtitle = session.isHydrating
        ? 'Restoring your saved session and checking whether onboarding is complete.'
        : session.isAuthenticated
            ? session.needsOnboarding
                ? 'Your account is signed in. Finish the setup flow before the main app shell opens.'
                : 'Your account is signed in and your personal app shell is ready.'
            : 'Create an account or sign in to access your own meals, nutrition, progress, and settings.';

    return AppScaffold(
      appBar: const AppTopAppBar(
        title: 'Welcome',
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppStandardCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fitness App',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(subtitle, style: theme.textTheme.bodyLarge),
                  SizedBox(height: tokens.sectionSpacing),
                  if (session.isHydrating)
                    const AppLoadingBlock(
                      title: 'Restoring session',
                      message:
                          'Checking the saved token on this device before opening the app.',
                    )
                  else if (!session.isAuthenticated) ...[
                    AppPrimaryButton(
                      label: 'Log in',
                      expand: true,
                      onPressed: () => context.go(AppRoutePaths.login),
                    ),
                    const SizedBox(height: 12),
                    AppSecondaryButton(
                      label: 'Create account',
                      expand: true,
                      onPressed: () => context.go(AppRoutePaths.signup),
                    ),
                  ] else if (session.needsOnboarding) ...[
                    AppPrimaryButton(
                      label: 'Continue onboarding',
                      expand: true,
                      onPressed: () => context.go(AppRoutePaths.onboardingGoal),
                    ),
                    const SizedBox(height: 12),
                    AppSecondaryButton(
                      label: 'Sign out',
                      expand: true,
                      onPressed: () => _signOut(ref),
                    ),
                  ] else ...[
                    AppPrimaryButton(
                      label: 'Open Today',
                      expand: true,
                      onPressed: () => context.go(AppRoutePaths.today),
                    ),
                    const SizedBox(height: 12),
                    AppSecondaryButton(
                      label: 'Sign out',
                      expand: true,
                      onPressed: () => _signOut(ref),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: tokens.sectionSpacing),
            if (!session.isHydrating && !session.isAuthenticated)
              const AppEmptyStateBlock(
                title: 'No session yet',
                message:
                    'Create a new account to begin onboarding, or log back in to reopen your existing data.',
              )
            else if (!session.isHydrating)
              AppStandardCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current session',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(session.displayName ?? 'User'),
                    const SizedBox(height: 4),
                    Text(session.email ?? 'No email captured yet'),
                    const SizedBox(height: 16),
                    Text(
                      session.needsOnboarding
                          ? 'Onboarding draft: $completedSteps of 4 steps complete.'
                          : 'Authenticated routes are available for this account.',
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
                    'Configured API base URL',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(Environment.defaultApiBaseUrl),
                ],
              ),
            ),
            SizedBox(height: tokens.sectionSpacing),
            const AppEmptyStateBlock(
              title: 'Real auth is active',
              message:
                  'This build now uses backend signup, login, bearer auth, and session restore instead of the earlier dev-only auth path.',
            ),
          ],
        ),
      ),
    );
  }
}

