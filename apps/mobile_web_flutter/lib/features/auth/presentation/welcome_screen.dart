import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/environment.dart';
import '../../../core/presentation/widgets/widgets.dart';
import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../application/auth_session.dart';
import '../../onboarding/application/onboarding_controller.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  void _signOut(WidgetRef ref) {
    ref.read(authSessionProvider.notifier).signOut();
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

    final subtitle = session.isAuthenticated
        ? session.needsOnboarding
            ? 'Local session active. Keep moving through the setup flow before the protected app routes open up.'
            : 'Local session active. The app shell is open, while real backend auth and secure storage remain deferred.'
        : 'Preview the authentication and onboarding flow with local state before real backend providers are connected.';

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
                    'Authentication-ready shell',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(subtitle, style: theme.textTheme.bodyLarge),
                  SizedBox(height: tokens.sectionSpacing),
                  if (!session.isAuthenticated) ...[
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
                      label: 'Open Today preview',
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
            if (!session.isAuthenticated)
              const AppEmptyStateBlock(
                title: 'No local session yet',
                message:
                    'Sign up to enter the onboarding sequence, or use login to preview the protected shell without real backend auth.',
              )
            else
              AppStandardCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preview session',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(session.displayName ?? 'Preview User'),
                    const SizedBox(height: 4),
                    Text(session.email ?? 'No email captured yet'),
                    const SizedBox(height: 16),
                    Text(
                      session.needsOnboarding
                          ? 'Onboarding saved locally: $completedSteps of 4 steps complete.'
                          : 'Protected routes are available in preview mode.',
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
              title: 'Preview flow only',
              message:
                  'Authentication and onboarding state are local-only in this milestone. Real backend auth integration is intentionally deferred.',
            ),
          ],
        ),
      ),
    );
  }
}