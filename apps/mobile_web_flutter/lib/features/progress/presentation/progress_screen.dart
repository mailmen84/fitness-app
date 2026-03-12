import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/widgets/widgets.dart';
import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../application/progress_overview_controller.dart';
import '../domain/progress_models.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  static const _monthNames = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String _errorMessage(Object error) {
    final message = error.toString().trim();
    return message.startsWith('Exception: ')
        ? message.substring('Exception: '.length)
        : message;
  }

  String _formatLongDate(DateTime date) {
    final localDate = date.toLocal();
    return '${_monthNames[localDate.month - 1]} '
        '${localDate.day}, '
        '${localDate.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = AppTheme.of(context);
    final state = ref.watch(progressOverviewControllerProvider);
    final controller = ref.read(progressOverviewControllerProvider.notifier);

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
                  'Progress foundation',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Progress overview',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track the latest body weight, recent body measurements, and the current goal without adding advanced analytics yet.',
                  style: theme.textTheme.bodyLarge,
                ),
                SizedBox(height: tokens.sectionSpacing),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    AppPrimaryButton(
                      label: 'Add weight',
                      onPressed: () => context.go(AppRoutePaths.progressAddWeight),
                    ),
                    AppSecondaryButton(
                      label: 'Add measurement',
                      onPressed: () =>
                          context.go(AppRoutePaths.progressAddMeasurement),
                    ),
                    AppSecondaryButton(
                      label: 'Weight history',
                      onPressed: () => context.go(AppRoutePaths.progressWeight),
                    ),
                    AppSecondaryButton(
                      label: 'Measurement history',
                      onPressed: () =>
                          context.go(AppRoutePaths.progressMeasurements),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: tokens.sectionSpacing),
          state.when(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            loading: () => const AppLoadingBlock(
              title: 'Loading progress',
              message:
                  'Pulling recent weight, measurement snapshots, and the current goal summary.',
            ),
            error: (error, _) => AppErrorBlock(
              title: 'Could not load progress',
              message: _errorMessage(error),
              action: AppPrimaryButton(
                label: 'Retry',
                expand: true,
                onPressed: controller.reload,
              ),
            ),
            data: (value) => _ProgressOverviewContent(
              data: value,
              formatLongDate: _formatLongDate,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressOverviewContent extends StatelessWidget {
  const _ProgressOverviewContent({
    required this.data,
    required this.formatLongDate,
  });

  final ProgressOverviewData data;
  final String Function(DateTime date) formatLongDate;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.isEmpty)
          AppEmptyStateBlock(
            title: 'No progress entries yet',
            message:
                'Log a weight entry or a body measurement to start building the Progress history for this account.',
            action: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AppPrimaryButton(
                  label: 'Add weight',
                  onPressed: () => context.go(AppRoutePaths.progressAddWeight),
                ),
                AppSecondaryButton(
                  label: 'Add measurement',
                  onPressed: () =>
                      context.go(AppRoutePaths.progressAddMeasurement),
                ),
              ],
            ),
          )
        else
          _ProgressSummaryGrid(
            data: data,
            formatLongDate: formatLongDate,
          ),
      ],
    );
  }
}

class _ProgressSummaryGrid extends StatelessWidget {
  const _ProgressSummaryGrid({
    required this.data,
    required this.formatLongDate,
  });

  final ProgressOverviewData data;
  final String Function(DateTime date) formatLongDate;

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
              child: _SummaryCard(
                title: 'Latest weight',
                child: _LatestWeightBody(
                  entry: data.latestWeight,
                  formatLongDate: formatLongDate,
                ),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                title: 'Weight trend',
                child: _WeightTrendBody(
                  data: data,
                  formatLongDate: formatLongDate,
                ),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                title: 'Latest measurements',
                child: _LatestMeasurementsBody(
                  measurements: data.latestMeasurements,
                  formatLongDate: formatLongDate,
                ),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                title: 'Current goal',
                child: _GoalSummaryBody(goal: data.currentGoal),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppStandardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _LatestWeightBody extends StatelessWidget {
  const _LatestWeightBody({
    required this.entry,
    required this.formatLongDate,
  });

  final WeightLogEntry? entry;
  final String Function(DateTime date) formatLongDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final latestEntry = entry;

    if (latestEntry == null) {
      return Text(
        'No weight logged yet. Add the first entry to start the trend summary.',
        style: theme.textTheme.bodyMedium,
      );
    }

    final note = latestEntry.note;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          latestEntry.formattedWeight,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          formatLongDate(latestEntry.measuredAt),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        if (note != null && note.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(note, style: theme.textTheme.bodyMedium),
        ],
      ],
    );
  }
}

class _WeightTrendBody extends StatelessWidget {
  const _WeightTrendBody({
    required this.data,
    required this.formatLongDate,
  });

  final ProgressOverviewData data;
  final String Function(DateTime date) formatLongDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final latestWeight = data.latestWeight;

    if (latestWeight == null) {
      return Text(
        'Log a first weight entry to unlock the trend summary.',
        style: theme.textTheme.bodyMedium,
      );
    }

    final trendLabel = data.weightChangeLabel;
    final previousWeight = data.previousWeight;
    if (trendLabel == null || previousWeight == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Need one more weight entry',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The latest entry is saved. Add another one later to compare weight change over time.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          trendLabel,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Previous entry: ${previousWeight.formattedWeight}',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(
          formatLongDate(previousWeight.measuredAt),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _LatestMeasurementsBody extends StatelessWidget {
  const _LatestMeasurementsBody({
    required this.measurements,
    required this.formatLongDate,
  });

  final List<LatestMeasurementSummary> measurements;
  final String Function(DateTime date) formatLongDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (measurements.isEmpty) {
      return Text(
        'No body measurements logged yet. Add waist, hips, chest, or other snapshots to see them here.',
        style: theme.textTheme.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < measurements.length; index++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      measurements[index].displayMeasurementType,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatLongDate(measurements[index].measuredAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                measurements[index].formattedValue,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (index < measurements.length - 1) const Divider(height: 24),
        ],
      ],
    );
  }
}

class _GoalSummaryBody extends StatelessWidget {
  const _GoalSummaryBody({required this.goal});

  final ProgressGoalSummary? goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentGoal = goal;

    if (currentGoal == null) {
      return Text(
        'No active goal is saved yet. Once goals are available, the current target will appear here.',
        style: theme.textTheme.bodyMedium,
      );
    }

    final formattedTarget = currentGoal.formattedTarget;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          currentGoal.title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (formattedTarget != null) ...[
          const SizedBox(height: 8),
          Text(
            'Target $formattedTarget',
            style: theme.textTheme.bodyMedium,
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'Goal code: ${currentGoal.code}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
