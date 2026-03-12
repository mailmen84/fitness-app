import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/widgets/widgets.dart';
import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/validation/form_validators.dart';
import '../application/progress_overview_controller.dart';
import '../application/weight_log_list_controller.dart';
import '../application/weight_log_submission_controller.dart';

class AddWeightScreen extends ConsumerStatefulWidget {
  const AddWeightScreen({super.key});

  @override
  ConsumerState<AddWeightScreen> createState() => _AddWeightScreenState();
}

class _AddWeightScreenState extends ConsumerState<AddWeightScreen> {
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

  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();

  String _unit = 'kg';
  DateTime _measuredAt = DateTime.now();

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

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

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _measuredAt,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null) {
      return;
    }

    setState(() {
      _measuredAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        _measuredAt.hour,
        _measuredAt.minute,
      );
    });
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final weight = double.parse(_weightController.text.trim());
    final success = await ref
        .read(weightLogSubmissionControllerProvider.notifier)
        .submit(
          measuredAt: _measuredAt,
          weight: weight,
          unit: _unit,
          note: _noteController.text,
        );

    if (!mounted || !success) {
      return;
    }

    await ref.read(progressOverviewControllerProvider.notifier).reload();
    await ref.read(weightLogListControllerProvider.notifier).reload();

    if (!mounted) {
      return;
    }
    context.go(AppRoutePaths.progressWeight);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTheme.of(context);
    final submissionState = ref.watch(weightLogSubmissionControllerProvider);
    final isSubmitting = submissionState.isLoading;
    final submissionError = switch (submissionState) {
      AsyncError<void>(:final error) => _errorMessage(error),
      _ => null,
    };

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
                  'Add weight entry',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Log a body weight check-in for the Progress overview and recent history.',
                  style: theme.textTheme.bodyLarge,
                ),
                SizedBox(height: tokens.sectionSpacing),
                AppSecondaryButton(
                  label: 'Back to weight history',
                  onPressed: () => context.go(AppRoutePaths.progressWeight),
                ),
              ],
            ),
          ),
          SizedBox(height: tokens.sectionSpacing),
          AppStandardCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Measured on',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatLongDate(_measuredAt),
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  AppSecondaryButton(
                    label: 'Change date',
                    onPressed: isSubmitting ? null : _pickDate,
                  ),
                  SizedBox(height: tokens.sectionSpacing),
                  AppTextField(
                    label: 'Weight',
                    controller: _weightController,
                    hintText: '84.2',
                    helperText: 'Use your latest scale reading.',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) => FormValidators.decimal(
                      value,
                      label: 'Weight',
                      min: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _unit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: const [
                      DropdownMenuItem(value: 'kg', child: Text('kg')),
                      DropdownMenuItem(value: 'lb', child: Text('lb')),
                    ],
                    onChanged: isSubmitting
                        ? null
                        : (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              _unit = value;
                            });
                          },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Note',
                    controller: _noteController,
                    hintText: 'Optional context',
                    helperText:
                        'Optional: morning check-in, after training, travel day, and so on.',
                    maxLines: 3,
                  ),
                  if (submissionError != null) ...[
                    SizedBox(height: tokens.sectionSpacing),
                    AppErrorBlock(
                      title: 'Could not save weight',
                      message: submissionError,
                    ),
                  ],
                  if (isSubmitting) ...[
                    SizedBox(height: tokens.sectionSpacing),
                    const AppLoadingBlock(
                      title: 'Saving weight',
                      message:
                          'Persisting the new entry and refreshing Progress data.',
                    ),
                  ],
                  SizedBox(height: tokens.sectionSpacing),
                  AppPrimaryButton(
                    label: 'Save weight',
                    expand: true,
                    onPressed: isSubmitting ? null : _submit,
                  ),
                  const SizedBox(height: 12),
                  AppSecondaryButton(
                    label: 'Cancel',
                    expand: true,
                    onPressed: isSubmitting
                        ? null
                        : () => context.go(AppRoutePaths.progressWeight),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
