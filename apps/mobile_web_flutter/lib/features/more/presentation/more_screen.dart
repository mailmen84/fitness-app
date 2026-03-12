import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/environment.dart';
import '../../../core/presentation/widgets/widgets.dart';
import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_session.dart';
import '../application/current_goal_controller.dart';
import '../application/current_user_controller.dart';
import '../application/preferences_controller.dart';
import '../domain/more_models.dart';
import 'more_presentation_utils.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = AppTheme.of(context);
    final currentUserState = ref.watch(currentUserControllerProvider);
    final currentGoalState = ref.watch(currentGoalControllerProvider);
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
                  'More & settings',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage profile details, goals, preferences, and placeholder areas from one place without expanding product scope.',
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          SizedBox(height: tokens.sectionSpacing),
          currentUserState.when(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            loading: () => const AppLoadingBlock(
              title: 'Loading account summary',
              message:
                  'Pulling the current profile, goal, and preference summaries.',
            ),
            error: (error, _) => AppErrorBlock(
              title: 'Could not load account summary',
              message: moreErrorMessage(error),
              action: AppPrimaryButton(
                label: 'Retry',
                expand: true,
                onPressed: ref
                    .read(currentUserControllerProvider.notifier)
                    .reload,
              ),
            ),
            data: (value) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileSummaryCard(
                  user: value,
                  onEditProfile: () => context.go(AppRoutePaths.moreProfile),
                ),
                SizedBox(height: tokens.sectionSpacing),
                _SettingsSnapshotGrid(
                  currentGoalState: currentGoalState,
                  preferencesState: preferencesState,
                  onOpenGoals: () => context.go(AppRoutePaths.moreGoals),
                  onOpenPreferences: () =>
                      context.go(AppRoutePaths.morePreferences),
                  onRetryGoals: ref
                      .read(currentGoalControllerProvider.notifier)
                      .reload,
                  onRetryPreferences: ref
                      .read(preferencesControllerProvider.notifier)
                      .reload,
                ),
                SizedBox(height: tokens.sectionSpacing),
                _NavigationCard(
                  onOpenProfile: () => context.go(AppRoutePaths.moreProfile),
                  onOpenGoals: () => context.go(AppRoutePaths.moreGoals),
                  onOpenPreferences: () =>
                      context.go(AppRoutePaths.morePreferences),
                  onOpenPed: () => context.go(AppRoutePaths.ped),
                  onOpenSupport: () => context.go(AppRoutePaths.moreSupport),
                ),
                SizedBox(height: tokens.sectionSpacing),
                AppStandardCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'App info',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'API base URL',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(Environment.defaultApiBaseUrl),
                      const SizedBox(height: 16),
                      Text(
                        'Auth in this repository is still dev-only. Sign out only clears local preview state until real auth is added.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      AppSecondaryButton(
                        label: 'Sign out (preview)',
                        expand: true,
                        onPressed: () {
                          ref.read(authSessionProvider.notifier).signOut();
                          context.go(AppRoutePaths.welcome);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({
    required this.user,
    required this.onEditProfile,
  });

  final CurrentUserData user;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profile = user.profile;

    final fullName = profile?.fullName;
    final heightLabel = profile?.heightLabel;
    final birthDate = profile?.birthDate;
    final bio = profile?.bio?.trim();

    return AppStandardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                child: Text(
                  user.initials,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user.email,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (fullName != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        fullName,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (profile == null || profile.isEmpty)
            const Text(
              'No profile details are saved yet. Add basic info like height, birth date, or a short bio from Profile settings.',
            )
          else ...[
            if (heightLabel != null)
              _DetailRow(label: 'Height', value: heightLabel),
            if (birthDate != null)
              _DetailRow(
                label: 'Birth date',
                value: formatMoreLongDate(birthDate),
              ),
            if (bio != null && bio.isNotEmpty)
              _DetailRow(label: 'Bio', value: bio),
          ],
          const SizedBox(height: 20),
          AppPrimaryButton(
            label: 'Edit profile',
            expand: true,
            onPressed: onEditProfile,
          ),
        ],
      ),
    );
  }
}

class _SettingsSnapshotGrid extends StatelessWidget {
  const _SettingsSnapshotGrid({
    required this.currentGoalState,
    required this.preferencesState,
    required this.onOpenGoals,
    required this.onOpenPreferences,
    required this.onRetryGoals,
    required this.onRetryPreferences,
  });

  final AsyncValue<CurrentGoalData?> currentGoalState;
  final AsyncValue<PreferenceData> preferencesState;
  final VoidCallback onOpenGoals;
  final VoidCallback onOpenPreferences;
  final VoidCallback onRetryGoals;
  final VoidCallback onRetryPreferences;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTwoColumn = constraints.maxWidth >= 760;
        final cardWidth = isTwoColumn
            ? (constraints.maxWidth - tokens.sectionSpacing) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: tokens.sectionSpacing,
          runSpacing: tokens.sectionSpacing,
          children: [
            SizedBox(
              width: cardWidth,
              child: _GoalSnapshotCard(
                state: currentGoalState,
                onOpen: onOpenGoals,
                onRetry: onRetryGoals,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _PreferencesSnapshotCard(
                state: preferencesState,
                onOpen: onOpenPreferences,
                onRetry: onRetryPreferences,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GoalSnapshotCard extends StatelessWidget {
  const _GoalSnapshotCard({
    required this.state,
    required this.onOpen,
    required this.onRetry,
  });

  final AsyncValue<CurrentGoalData?> state;
  final VoidCallback onOpen;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppStandardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Goals',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          state.when(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            loading: () => const Text(
              'Loading the current goal summary...',
            ),
            error: (error, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(moreErrorMessage(error)),
                const SizedBox(height: 12),
                AppSecondaryButton(
                  label: 'Retry',
                  onPressed: onRetry,
                ),
              ],
            ),
            data: (value) {
              final targetLabel = value?.targetLabel;
              return value == null
                  ? const Text(
                      'No current goal is saved yet. Add one from Goal settings.',
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(value.codeLabel),
                        if (targetLabel != null) ...[
                          const SizedBox(height: 6),
                          Text('Target $targetLabel'),
                        ],
                      ],
                    );
            },
          ),
          const SizedBox(height: 20),
          AppSecondaryButton(
            label: 'Open goals',
            expand: true,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}

class _PreferencesSnapshotCard extends StatelessWidget {
  const _PreferencesSnapshotCard({
    required this.state,
    required this.onOpen,
    required this.onRetry,
  });

  final AsyncValue<PreferenceData> state;
  final VoidCallback onOpen;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppStandardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Units & preferences',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          state.when(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            loading: () => const Text(
              'Loading preference summary...',
            ),
            error: (error, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(moreErrorMessage(error)),
                const SizedBox(height: 12),
                AppSecondaryButton(
                  label: 'Retry',
                  onPressed: onRetry,
                ),
              ],
            ),
            data: (value) {
              final dailyCalorieTargetLabel = value.dailyCalorieTargetLabel;
              final dailyProteinTargetLabel = value.dailyProteinTargetLabel;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value.unitSystemLabel,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('Timezone ${value.timezone}'),
                  const SizedBox(height: 6),
                  Text('Week starts on ${value.weekStartsOnLabel}'),
                  if (dailyCalorieTargetLabel != null) ...[
                    const SizedBox(height: 6),
                    Text('Calories $dailyCalorieTargetLabel'),
                  ],
                  if (dailyProteinTargetLabel != null) ...[
                    const SizedBox(height: 6),
                    Text('Protein $dailyProteinTargetLabel'),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          AppSecondaryButton(
            label: 'Open preferences',
            expand: true,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}

class _NavigationCard extends StatelessWidget {
  const _NavigationCard({
    required this.onOpenProfile,
    required this.onOpenGoals,
    required this.onOpenPreferences,
    required this.onOpenPed,
    required this.onOpenSupport,
  });

  final VoidCallback onOpenProfile;
  final VoidCallback onOpenGoals;
  final VoidCallback onOpenPreferences;
  final VoidCallback onOpenPed;
  final VoidCallback onOpenSupport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppStandardCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              'Settings navigation',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _NavigationRow(
            icon: Icons.person_outline_rounded,
            title: 'Profile settings',
            subtitle: 'Name, email, height, birth date, and bio.',
            onTap: onOpenProfile,
          ),
          _NavigationRow(
            icon: Icons.flag_outlined,
            title: 'Goals settings',
            subtitle: 'Current goal, target value, notes, and dates.',
            onTap: onOpenGoals,
          ),
          _NavigationRow(
            icon: Icons.straighten_rounded,
            title: 'Units and preferences',
            subtitle: 'Unit system, timezone, week start, and daily targets.',
            onTap: onOpenPreferences,
          ),
          _NavigationRow(
            icon: Icons.science_outlined,
            title: 'PED placeholder',
            subtitle: 'Visible, inactive, and planned for later.',
            onTap: onOpenPed,
          ),
          _NavigationRow(
            icon: Icons.support_agent_rounded,
            title: 'Support placeholder',
            subtitle: 'Reserved for later support and help surfaces.',
            onTap: onOpenSupport,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _NavigationRow extends StatelessWidget {
  const _NavigationRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}