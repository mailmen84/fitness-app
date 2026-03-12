import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/widgets/widgets.dart';
import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/validation/form_validators.dart';
import '../application/measurement_log_list_controller.dart';
import '../application/measurement_log_submission_controller.dart';
import '../application/progress_overview_controller.dart';
import '../domain/progress_models.dart';

class AddMeasurementScreen extends ConsumerStatefulWidget {
  const AddMeasurementScreen({super.key});

  @override
  ConsumerState<AddMeasurementScreen> createState() =>
      _AddMeasurementScreenState();
}

class _AddMeasurementScreenState extends ConsumerState<AddMeasurementScreen> {
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

  static const _measurementTypes = <String>[
    'waist',
    'hips',
    'chest',
    'arm',
    'thigh',
    'neck',
  ];

  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _noteController = TextEditingController();

  String _measurementType = _measurementTypes.first;
  String _unit = 'cm';
  DateTime _measuredAt = DateTime.now();

  @override
  void dispose() {
    _valueController.dispose();
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

    final value = double.parse(_valueController.text.trim());
    final success = await ref
        .read(measurementLogSubmissionControllerProvider.notifier)
        .submit(
          measurementType: _measurementType,
          measuredAt: _measuredAt,
          value: value,
          unit: _unit,
          note: _noteController.text,
        );

    if (!mounted || !success) {
      return;
    }

    await ref.read(progressOverviewControllerProvider.notifier).reload();
    await ref.read(measurementLogListControllerProvider.notifier).reload();

    if (!mounted) {
      return;
    }
    context.go(AppRoutePaths.progressMeasurements);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTheme.of(context);
    final submissionState = ref.watch(measurementLogSubmissionControllerProvider);
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
                  'Add measurement entry',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Log a simple body measurement snapshot for Progress history and summaries.',
                  style: theme.textTheme.bodyLarge,
                ),
                SizedBox(height: tokens.sectionSpacing),
                AppSecondaryButton(
                  label: 'Back to measurement history',
                  onPressed: () =>
                      context.go(AppRoutePaths.progressMeasurements),
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
                  DropdownButtonFormField<String>(
                    value: _measurementType,
                    decoration: const InputDecoration(labelText: 'Measurement type'),
                    items: _measurementTypes
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(formatProgressMeasurementLabel(type)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: isSubmitting
                        ? null
                        : (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              _measurementType = value;
                            });
                          },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Value',
                    controller: _valueController,
                    hintText: '82.0',
                    helperText: 'Enter the measurement for the selected body area.',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) => FormValidators.decimal(
                      value,
                      label: 'Value',
                      min: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _unit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: const [
                      DropdownMenuItem(value: 'cm', child: Text('cm')),
                      DropdownMenuItem(value: 'in', child: Text('in')),
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
                        'Optional: relaxed, post-workout, morning fasted, and so on.',
                    maxLines: 3,
                  ),
                  if (submissionError != null) ...[
                    SizedBox(height: tokens.sectionSpacing),
                    AppErrorBlock(
                      title: 'Could not save measurement',
                      message: submissionError,
                    ),
                  ],
                  if (isSubmitting) ...[
                    SizedBox(height: tokens.sectionSpacing),
                    const AppLoadingBlock(
                      title: 'Saving measurement',
                      message:
                          'Persisting the new entry and refreshing Progress data.',
                    ),
                  ],
                  SizedBox(height: tokens.sectionSpacing),
                  AppPrimaryButton(
                    label: 'Save measurement',
                    expand: true,
                    onPressed: isSubmitting ? null : _submit,
                  ),
                  const SizedBox(height: 12),
                  AppSecondaryButton(
                    label: 'Cancel',
                    expand: true,
                    onPressed: isSubmitting
                        ? null
                        : () => context.go(AppRoutePaths.progressMeasurements),
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
