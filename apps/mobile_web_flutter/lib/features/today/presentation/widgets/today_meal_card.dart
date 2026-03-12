import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/widgets.dart';
import '../../domain/today_dashboard.dart';

class TodayMealCard extends StatelessWidget {
  const TodayMealCard({
    required this.section,
    required this.onAddPressed,
    required this.onEntryPressed,
    super.key,
  });

  final TodayMealSection section;
  final VoidCallback onAddPressed;
  final ValueChanged<TodayMealEntry> onEntryPressed;

  String _sectionTotals(TodayMealSection section) {
    return '${section.caloriesTotal.toStringAsFixed(0)} kcal | '
        'P ${section.proteinTotal.toStringAsFixed(0)}g | '
        'C ${section.carbsTotal.toStringAsFixed(0)}g | '
        'F ${section.fatTotal.toStringAsFixed(0)}g';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppStandardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(section.icon, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _sectionTotals(section),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onAddPressed,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (section.isEmpty)
            Text(
              'No items logged for this meal yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            Column(
              children: [
                for (var index = 0; index < section.entries.length; index++) ...[
                  _TodayMealEntryRow(
                    entry: section.entries[index],
                    onPressed: () => onEntryPressed(section.entries[index]),
                  ),
                  if (index < section.entries.length - 1)
                    const Divider(height: 24),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _TodayMealEntryRow extends StatelessWidget {
  const _TodayMealEntryRow({
    required this.entry,
    required this.onPressed,
  });

  final TodayMealEntry entry;
  final VoidCallback onPressed;

  String _macroLine() {
    return 'P ${entry.protein.toStringAsFixed(0)}g | '
        'C ${entry.carbs.toStringAsFixed(0)}g | '
        'F ${entry.fat.toStringAsFixed(0)}g';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onPressed,
      child: Padding(
        padding: EdgeInsets.zero,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.quantityLabel,
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
                  if (entry.notes != null && entry.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.notes!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry.calories.toStringAsFixed(0)} kcal',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Icon(Icons.chevron_right_rounded, color: colorScheme.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
