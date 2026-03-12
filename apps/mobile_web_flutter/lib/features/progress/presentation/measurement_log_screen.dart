import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/widgets/widgets.dart';
import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../application/measurement_log_list_controller.dart';
import '../domain/progress_models.dart';

class MeasurementLogScreen extends ConsumerWidget {
  const MeasurementLogScreen({super.key});

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
    final state = ref.watch(measurementLogListControllerProvider);
    final controller = ref.read(measurementLogListControllerProvider.notifier);

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
                  'Measurement history',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Review recent waist, hips, chest, or other body measurement snapshots.',
                  style: theme.textTheme.bodyLarge,
                ),
                SizedBox(height: tokens.sectionSpacing),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    AppPrimaryButton(
                      label: 'Add measurement',
                      onPressed: () =>
                          context.go(AppRoutePaths.progressAddMeasurement),
                    ),
                    AppSecondaryButton(
                      label: 'Back to Progress',
                      onPressed: () => context.go(AppRoutePaths.progress),
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
              title: 'Loading measurements',
              message: 'Pulling recent body measurement entries for this user.',
            ),
            error: (error, _) => AppErrorBlock(
              title: 'Could not load measurements',
              message: _errorMessage(error),
              action: AppPrimaryButton(
                label: 'Retry',
                expand: true,
                onPressed: controller.reload,
              ),
            ),
            data: (value) => value.isEmpty
                ? AppEmptyStateBlock(
                    title: 'No measurements yet',
                    message:
                        'Add a first measurement snapshot to start building progress history here.',
                    action: AppPrimaryButton(
                      label: 'Add measurement',
                      expand: true,
                      onPressed: () =>
                          context.go(AppRoutePaths.progressAddMeasurement),
                    ),
                  )
                : AppStandardCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent entries',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        for (var index = 0; index < value.length; index++) ...[
                          _MeasurementLogRow(
                            entry: value[index],
                            formatLongDate: _formatLongDate,
                          ),
                          if (index < value.length - 1) const Divider(height: 28),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MeasurementLogRow extends StatelessWidget {
  const _MeasurementLogRow({
    required this.entry,
    required this.formatLongDate,
  });

  final MeasurementLogEntry entry;
  final String Function(DateTime date) formatLongDate;

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
                entry.displayMeasurementType,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatLongDate(entry.measuredAt),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (entry.note != null && entry.note!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(entry.note!, style: theme.textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        const SizedBox(width: 16),
        Text(
          entry.formattedValue,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
