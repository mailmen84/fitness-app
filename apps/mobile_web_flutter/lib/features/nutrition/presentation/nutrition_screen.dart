import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/widgets/widgets.dart';
import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../application/nutrition_overview_controller.dart';
import '../domain/nutrition_overview.dart';

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

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

  static const _shortMonthNames = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _errorMessage(Object error) {
    final message = error.toString().trim();
    return message.startsWith('Exception: ')
        ? message.substring('Exception: '.length)
        : message;
  }

  String _formatLongDate(DateTime date) {
    final normalized = DateUtils.dateOnly(date);
    return '${_monthNames[normalized.month - 1]} '
        '${normalized.day}, '
        '${normalized.year}';
  }

  String _formatShortDate(DateTime date) {
    final normalized = DateUtils.dateOnly(date);
    return '${_shortMonthNames[normalized.month - 1]} ${normalized.day}';
  }

  String _fallbackPeriodLabel(
    NutritionRangeOption selectedRange,
    DateTime anchorDate,
  ) {
    return switch (selectedRange) {
      NutritionRangeOption.day => _formatLongDate(anchorDate),
      NutritionRangeOption.week => 'Week of ${_formatShortDate(anchorDate)}',
      NutritionRangeOption.month =>
        '${_monthNames[anchorDate.month - 1]} ${anchorDate.year}',
    };
  }

  String _periodLabel(
    NutritionOverviewData? overview,
    NutritionOverviewViewState state,
  ) {
    if (overview == null) {
      return _fallbackPeriodLabel(state.selectedRange, state.anchorDate);
    }

    return switch (overview.range) {
      NutritionRangeOption.day => _formatLongDate(overview.anchorDate),
      NutritionRangeOption.week =>
        '${_formatShortDate(overview.periodStart)} - ${_formatShortDate(overview.periodEnd)}',
      NutritionRangeOption.month =>
        '${_monthNames[overview.periodStart.month - 1]} ${overview.periodStart.year}',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = AppTheme.of(context);
    final state = ref.watch(nutritionOverviewControllerProvider);
    final controller = ref.read(nutritionOverviewControllerProvider.notifier);
    final overview = state.overview.valueOrNull;
    final isTodayAnchor = DateUtils.isSameDay(state.anchorDate, DateTime.now());

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
                  'Nutrition overview',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _periodLabel(overview, state),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Lightweight day, week, and month totals now come from the backend meal history and current targets where available.',
                  style: theme.textTheme.bodyLarge,
                ),
                SizedBox(height: tokens.sectionSpacing),
                SegmentedButton<NutritionRangeOption>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: NutritionRangeOption.day,
                      label: Text('Day'),
                    ),
                    ButtonSegment(
                      value: NutritionRangeOption.week,
                      label: Text('Week'),
                    ),
                    ButtonSegment(
                      value: NutritionRangeOption.month,
                      label: Text('Month'),
                    ),
                  ],
                  selected: {state.selectedRange},
                  onSelectionChanged: (selection) {
                    if (selection.isEmpty) {
                      return;
                    }
                    controller.setRange(selection.first);
                  },
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    AppSecondaryButton(
                      label: 'Previous ${state.selectedRange.label.toLowerCase()}',
                      onPressed: controller.loadPreviousRange,
                    ),
                    if (!isTodayAnchor)
                      AppSecondaryButton(
                        label: 'Jump to today',
                        onPressed: controller.jumpToToday,
                      ),
                    AppSecondaryButton(
                      label: 'Next ${state.selectedRange.label.toLowerCase()}',
                      onPressed: controller.loadNextRange,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: tokens.sectionSpacing),
          state.overview.when(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            loading: () => const AppLoadingBlock(
              title: 'Loading nutrition',
              message:
                  'Calculating totals, targets, and top contributors for the selected range.',
            ),
            error: (error, _) => AppErrorBlock(
              title: 'Could not load nutrition',
              message: _errorMessage(error),
              action: AppPrimaryButton(
                label: 'Retry',
                expand: true,
                onPressed: controller.retry,
              ),
            ),
            data: (value) => _NutritionOverviewContent(
              data: value,
              onOpenAdd: () => context.go(AppRoutePaths.add),
              onOpenToday: () => context.go(AppRoutePaths.today),
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionOverviewContent extends StatelessWidget {
  const _NutritionOverviewContent({
    required this.data,
    required this.onOpenAdd,
    required this.onOpenToday,
  });

  final NutritionOverviewData data;
  final VoidCallback onOpenAdd;
  final VoidCallback onOpenToday;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NutritionSummaryGrid(data: data),
        SizedBox(height: tokens.sectionSpacing),
        _NutritionCategoryCard(data: data),
        SizedBox(height: tokens.sectionSpacing),
        if (data.isEmpty)
          AppEmptyStateBlock(
            title: 'No nutrition logged in this range',
            message:
                'Log food from Today or the Add tab, then this overview will populate calories, macros, and contributors.',
            action: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AppPrimaryButton(
                  label: 'Open add flow',
                  onPressed: onOpenAdd,
                ),
                AppSecondaryButton(
                  label: 'Open Today',
                  onPressed: onOpenToday,
                ),
              ],
            ),
          )
        else if (data.topContributors.isEmpty)
          const AppEmptyStateBlock(
            title: 'No contributors yet',
            message:
                'Nutrition totals are available, but there are no ranked contributor rows for this period yet.',
          )
        else
          _TopContributorsCard(contributors: data.topContributors),
      ],
    );
  }
}

class _NutritionSummaryGrid extends StatelessWidget {
  const _NutritionSummaryGrid({required this.data});

  final NutritionOverviewData data;

  String _metricLabel(double amount, String unit) {
    return '${amount.toStringAsFixed(0)} $unit';
  }

  String? _targetLabel(double? target, String unit) {
    if (target == null || target <= 0) {
      return null;
    }
    return 'Target ${target.toStringAsFixed(0)} $unit';
  }

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
              child: _NutritionSummaryCard(
                title: 'Calories',
                headline: _metricLabel(data.caloriesTotal, 'kcal'),
                child: Text(
                  _targetLabel(data.targets.calories, 'kcal') ??
                      'No calorie target saved yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _NutritionSummaryCard(
                title: 'Macros',
                headline: 'Protein, carbs, and fat',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MacroSummaryRow(
                      label: 'Protein',
                      value: _metricLabel(data.proteinTotal, 'g'),
                      target: _targetLabel(data.targets.protein, 'g'),
                    ),
                    const SizedBox(height: 10),
                    _MacroSummaryRow(
                      label: 'Carbs',
                      value: _metricLabel(data.carbsTotal, 'g'),
                      target: _targetLabel(data.targets.carbs, 'g'),
                    ),
                    const SizedBox(height: 10),
                    _MacroSummaryRow(
                      label: 'Fat',
                      value: _metricLabel(data.fatTotal, 'g'),
                      target: _targetLabel(data.targets.fat, 'g'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NutritionSummaryCard extends StatelessWidget {
  const _NutritionSummaryCard({
    required this.title,
    required this.headline,
    required this.child,
  });

  final String title;
  final String headline;
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
          const SizedBox(height: 12),
          Text(
            headline,
            style: theme.textTheme.headlineSmall?.copyWith(
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

class _MacroSummaryRow extends StatelessWidget {
  const _MacroSummaryRow({
    required this.label,
    required this.value,
    required this.target,
  });

  final String label;
  final String value;
  final String? target;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodyMedium),
              if (target != null) ...[
                const SizedBox(height: 2),
                Text(
                  target!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _NutritionCategoryCard extends StatelessWidget {
  const _NutritionCategoryCard({required this.data});

  final NutritionOverviewData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppStandardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nutrient categories',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Targets appear where the current user profile already has them.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          for (var index = 0; index < data.categoryRows.length; index++) ...[
            _NutritionCategoryRowTile(row: data.categoryRows[index]),
            if (index < data.categoryRows.length - 1) const Divider(height: 28),
          ],
        ],
      ),
    );
  }
}

class _NutritionCategoryRowTile extends StatelessWidget {
  const _NutritionCategoryRowTile({required this.row});

  final NutritionCategoryRow row;

  double? _boundedProgress(double? value) {
    if (value == null) {
      return null;
    }
    if (value < 0) {
      return 0;
    }
    if (value > 1) {
      return 1;
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final boundedProgress = _boundedProgress(row.progressRatio);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                row.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${row.amount.toStringAsFixed(0)} ${row.unit}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          row.hasTarget
              ? 'Target ${row.target!.toStringAsFixed(0)} ${row.unit}'
              : 'No target saved yet.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        if (boundedProgress != null) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: boundedProgress,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(row.progressRatio! * 100).round()}% of target',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _TopContributorsCard extends StatelessWidget {
  const _TopContributorsCard({required this.contributors});

  final List<NutritionContributor> contributors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppStandardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top contributors',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ranked by calorie contribution for the selected range.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          for (var index = 0; index < contributors.length; index++) ...[
            _ContributorRow(contributor: contributors[index]),
            if (index < contributors.length - 1) const Divider(height: 28),
          ],
        ],
      ),
    );
  }
}

class _ContributorRow extends StatelessWidget {
  const _ContributorRow({required this.contributor});

  final NutritionContributor contributor;

  String _macroLine() {
    return 'P ${contributor.protein.toStringAsFixed(0)}g | '
        'C ${contributor.carbs.toStringAsFixed(0)}g | '
        'F ${contributor.fat.toStringAsFixed(0)}g';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contributor.foodName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${contributor.mealSectionTitle} • ${contributor.quantityLabel}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _macroLine(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Text(
          '${contributor.calories.toStringAsFixed(0)} kcal',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
