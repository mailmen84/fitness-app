import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/widgets.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../today/domain/today_dashboard.dart';

class MealLoggingTargetCard extends StatelessWidget {
  const MealLoggingTargetCard({
    required this.title,
    required this.description,
    required this.selectedDate,
    required this.selectedMealSection,
    required this.onPickDate,
    required this.onMealSectionSelected,
    super.key,
  });

  final String title;
  final String description;
  final DateTime selectedDate;
  final TodayMealSectionCode selectedMealSection;
  final VoidCallback onPickDate;
  final ValueChanged<TodayMealSectionCode> onMealSectionSelected;

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTheme.of(context);
    final colorScheme = theme.colorScheme;

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
            description,
            style: theme.textTheme.bodyMedium,
          ),
          SizedBox(height: tokens.sectionSpacing),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected date',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(selectedDate),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              AppSecondaryButton(
                label: 'Change date',
                onPressed: onPickDate,
              ),
            ],
          ),
          SizedBox(height: tokens.sectionSpacing),
          Text(
            'Meal section',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final section in TodayMealSectionCode.values)
                ChoiceChip(
                  label: Text(section.title),
                  selected: selectedMealSection == section,
                  onSelected: (_) => onMealSectionSelected(section),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
