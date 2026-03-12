import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/widgets/widgets.dart';
import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../application/weight_log_list_controller.dart';
import '../domain/progress_models.dart';

class WeightLogScreen extends ConsumerWidget {
  const WeightLogScreen({super.key});

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
    final state = ref.watch(weightLogListControllerProvider);
    final controller = ref.read(weightLogListControllerProvider.notifier);

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
                  'Weight history',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Review recent body weight entries and add a new check-in when needed.',
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
                      label: 'Back to overview',
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
              title: 'Loading weight history',
              message: 'Pulling recent body weight entries for this user.',
            ),
            error: (error, _) => AppErrorBlock(
              title: 'Could not load weight history',
              message: _errorMessage(error),
              action: AppPrimaryButton(
                label: 'Retry',
                expand: true,
                onPressed: controller.reload,
              ),
            ),
            data: (value) => value.isEmpty
                ? AppEmptyStateBlock(
                    title: 'No weight entries yet',
                    message:
                        'Add a first body weight log to start tracking recent history here.',
                    action: AppPrimaryButton(
                      label: 'Add weight',
                      expand: true,
                      onPressed: () =>
                          context.go(AppRoutePaths.progressAddWeight),
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
                          _WeightLogRow(
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

class _WeightLogRow extends StatelessWidget {
  const _WeightLogRow({
    required this.entry,
    required this.formatLongDate,
  });

  final WeightLogEntry entry;
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
                formatLongDate(entry.measuredAt),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (entry.note != null && entry.note!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  entry.note!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 16),
        Text(
          entry.formattedWeight,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
