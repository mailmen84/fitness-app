import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/widgets/widgets.dart';
import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../../add/application/meal_logging_flow_controller.dart';
import '../../more/application/preferences_controller.dart';
import '../../more/domain/more_models.dart';
import '../application/today_dashboard_controller.dart';
import '../domain/today_dashboard.dart';
import 'widgets/today_meal_card.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  static const _weekdayNames = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

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

  String _formatSelectedDay(DateTime date) {
    final normalized = DateUtils.dateOnly(date);
    return '${_weekdayNames[normalized.weekday - 1]}, '
        '${_monthNames[normalized.month - 1]} '
        '${normalized.day}';
  }

  String _relativeLabel(DateTime date) {
    final normalized = DateUtils.dateOnly(date);
    final today = DateUtils.dateOnly(DateTime.now());
    final difference = normalized.difference(today).inDays;
    if (difference == 0) {
      return 'Today';
    }
    if (difference == -1) {
      return 'Yesterday';
    }
    if (difference == 1) {
      return 'Tomorrow';
    }
    return 'Selected day';
  }

  String _errorMessage(Object error) {
    final message = error.toString().trim();
    return message.startsWith('Exception: ')
        ? message.substring('Exception: '.length)
        : message;
  }

  void _openQuickAdd(BuildContext context, WidgetRef ref, DateTime date) {
    ref.read(mealLoggingFlowControllerProvider.notifier).seed(selectedDate: date);
    context.go(AppRoutePaths.addQuick);
  }

  void _openSearchForSection(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
    TodayMealSectionCode section,
  ) {
    ref.read(mealLoggingFlowControllerProvider.notifier).seed(
          selectedDate: date,
          mealSection: section,
        );
    context.go(AppRoutePaths.addSearch);
  }

  void _openMealDetail(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
    TodayMealSectionCode section,
    TodayMealEntry entry,
  ) {
    ref.read(mealLoggingFlowControllerProvider.notifier).seed(
          selectedDate: date,
          mealSection: section,
        );
    context.go(AppRoutePaths.addMealDetail(entry.id), extra: entry);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = AppTheme.of(context);
    final state = ref.watch(todayDashboardControllerProvider);
    final controller = ref.read(todayDashboardControllerProvider.notifier);
    final isToday = DateUtils.isSameDay(state.selectedDate, DateTime.now());

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
                  _relativeLabel(state.selectedDate),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _formatSelectedDay(state.selectedDate),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Daily totals now come from the backend. Meal cards can open the add flow, and saved items round-trip back into this dashboard.',
                  style: theme.textTheme.bodyLarge,
                ),
                SizedBox(height: tokens.sectionSpacing),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    AppSecondaryButton(
                      label: 'Previous day',
                      onPressed: controller.loadPreviousDay,
                    ),
                    if (!isToday)
                      AppSecondaryButton(
                        label: 'Jump to today',
                        onPressed: controller.jumpToToday,
                      ),
                    AppSecondaryButton(
                      label: 'Next day',
                      onPressed: controller.loadNextDay,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: tokens.sectionSpacing),
          state.dashboard.when(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            loading: () => const AppLoadingBlock(
              title: 'Loading today',
              message:
                  'Pulling the selected day, summary totals, and meal sections.',
            ),
            error: (error, _) => AppErrorBlock(
              title: 'Could not load this day',
              message: _errorMessage(error),
              action: AppPrimaryButton(
                label: 'Retry',
                expand: true,
                onPressed: controller.retry,
              ),
            ),
            data: (value) => _TodayDashboardContent(
              data: value,
              onQuickAdd: () => _openQuickAdd(context, ref, state.selectedDate),
              onSearchForSection: (section) =>
                  _openSearchForSection(context, ref, state.selectedDate, section),
              onOpenMealDetail: (section, entry) => _openMealDetail(
                context,
                ref,
                state.selectedDate,
                section,
                entry,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayDashboardContent extends StatelessWidget {
  const _TodayDashboardContent({
    required this.data,
    required this.onQuickAdd,
    required this.onSearchForSection,
    required this.onOpenMealDetail,
  });

  final TodayDashboardData data;
  final VoidCallback onQuickAdd;
  final ValueChanged<TodayMealSectionCode> onSearchForSection;
  final void Function(TodayMealSectionCode section, TodayMealEntry entry)
      onOpenMealDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TodaySummaryGrid(data: data),
        SizedBox(height: tokens.sectionSpacing),
        AppStandardCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick actions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  AppPrimaryButton(
                    label: 'Add to meal',
                    onPressed: onQuickAdd,
                  ),
                  AppSecondaryButton(
                    label: 'Add breakfast',
                    onPressed: () => onSearchForSection(TodayMealSectionCode.breakfast),
                  ),
                  AppSecondaryButton(
                    label: 'Add dinner',
                    onPressed: () => onSearchForSection(TodayMealSectionCode.dinner),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (data.isEmpty) ...[
          SizedBox(height: tokens.sectionSpacing),
          const AppEmptyStateBlock(
            title: 'No meals logged for this day',
            message:
                'Breakfast, lunch, dinner, and snacks are ready. Use the add flow to search foods and start logging items for this day.',
          ),
        ],
        for (final section in data.mealSections) ...[
          SizedBox(height: tokens.sectionSpacing),
          TodayMealCard(
            section: section,
            onAddPressed: () => onSearchForSection(section.code),
            onEntryPressed: (entry) => onOpenMealDetail(section.code, entry),
          ),
        ],
      ],
    );
  }
}

class _TodaySummaryGrid extends ConsumerWidget {
  const _TodaySummaryGrid({required this.data});

  final TodayDashboardData data;

  String _caloriesHeadline(PreferenceData? prefs) {
    final base = '${data.caloriesTotal.toStringAsFixed(0)} kcal';
    final target = prefs?.dailyCalorieTarget;
    if (target == null) {
      return base;
    }
    return '$base / ${target.toStringAsFixed(0)} kcal';
  }

  String _macroValue(double current, double? target) {
    final base = '${current.toStringAsFixed(0)}g';
    if (target == null) {
      return base;
    }
    return '$base / ${target.toStringAsFixed(0)}g';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AppTheme.of(context);
    final preferencesState = ref.watch(preferencesControllerProvider);
    final preferences = preferencesState.asData?.value;

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
              child: _TodaySummaryCard(
                title: 'Calories',
                headline: _caloriesHeadline(preferences),
                child: Text(
                  preferences?.dailyCalorieTarget == null
                      ? 'Total energy for the selected day across all meal sections.'
                      : 'Total energy logged vs your daily calorie target.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _TodaySummaryCard(
                title: 'Macros',
                headline: 'Protein, carbs, and fat',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MacroRow(
                      label: 'Protein',
                      value: _macroValue(
                        data.proteinTotal,
                        preferences?.dailyProteinTarget,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _MacroRow(
                      label: 'Carbs',
                      value: _macroValue(
                        data.carbsTotal,
                        preferences?.dailyCarbsTarget,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _MacroRow(
                      label: 'Fat',
                      value: _macroValue(
                        data.fatTotal,
                        preferences?.dailyFatTarget,
                      ),
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

class _TodaySummaryCard extends StatelessWidget {
  const _TodaySummaryCard({
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

class _MacroRow extends StatelessWidget {
  const _MacroRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium,
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
