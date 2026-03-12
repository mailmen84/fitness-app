import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/widgets/widgets.dart';
import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/validation/form_validators.dart';
import '../../progress/application/progress_overview_controller.dart';
import '../application/current_goal_controller.dart';
import '../application/current_goal_submission_controller.dart';
import '../domain/more_models.dart';
import 'more_presentation_utils.dart';

class GoalSettingsScreen extends ConsumerStatefulWidget {
  const GoalSettingsScreen({super.key});

  @override
  ConsumerState<GoalSettingsScreen> createState() => _GoalSettingsScreenState();
}

class _GoalSettingsScreenState extends ConsumerState<GoalSettingsScreen> {
  static const _goalOptions = <String>[
    'cut',
    'maintain',
    'gain',
    'performance',
  ];

  static const _unitOptions = <String>[
    '',
    'kg',
    'lb',
    'kcal',
    'g',
    '%',
    'sessions',
    'days',
  ];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetValueController = TextEditingController();
  final _notesController = TextEditingController();

  ProviderSubscription<AsyncValue<CurrentGoalData?>>? _currentGoalSubscription;
  String _goalCode = _goalOptions.first;
  String _targetUnit = 'kg';
  DateTime? _startsOn;
  DateTime? _endsOn;
  bool _initializedForm = false;

  @override
  void initState() {
    super.initState();
    _currentGoalSubscription = ref.listenManual<AsyncValue<CurrentGoalData?>>(
      currentGoalControllerProvider,
      (previous, next) {
        if (_initializedForm) {
          return;
        }
        next.whenData(
          (goal) => _seedForm(
            goal,
            notify: previous != null,
          ),
        );
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _currentGoalSubscription?.close();
    _titleController.dispose();
    _targetValueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _defaultTitleForCode(String code) {
    return switch (code) {
      'cut' => 'Cut body fat',
      'maintain' => 'Maintain weight',
      'gain' => 'Build muscle',
      'performance' => 'Improve performance',
      _ => 'Goal',
    };
  }

  void _seedForm(CurrentGoalData? goal, {required bool notify}) {
    void apply() {
      if (goal == null) {
        _goalCode = _goalOptions.first;
        _titleController.text = _defaultTitleForCode(_goalCode);
        _targetValueController.clear();
        _targetUnit = 'kg';
        _notesController.clear();
        _startsOn = null;
        _endsOn = null;
      } else {
        _goalCode = goal.code.isEmpty ? _goalOptions.first : goal.code;
        if (!_goalOptions.contains(_goalCode)) {
          _goalCode = _goalOptions.first;
        }
        _titleController.text = goal.title;
        _targetValueController.text = goal.targetValue == null
            ? ''
            : formatMoreNumber(goal.targetValue!);
        _targetUnit = goal.targetUnit ?? '';
        if (!_unitOptions.contains(_targetUnit)) {
          _targetUnit = '';
        }
        _notesController.text = goal.notes ?? '';
        _startsOn = goal.startsOn;
        _endsOn = goal.endsOn;
      }
      _initializedForm = true;
    }

    if (!notify || !mounted) {
      apply();
      return;
    }

    setState(apply);
  }

  Future<void> _pickStartDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startsOn ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (pickedDate == null) {
      return;
    }
    setState(() {
      _startsOn = pickedDate;
      if (_endsOn != null && _endsOn!.isBefore(_startsOn!)) {
        _endsOn = _startsOn;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _endsOn ?? _startsOn ?? DateTime.now(),
      firstDate: _startsOn ?? DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (pickedDate == null) {
      return;
    }
    setState(() {
      _endsOn = pickedDate;
    });
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final targetValueText = _targetValueController.text.trim();
    final targetValue =
        targetValueText.isEmpty ? null : double.parse(targetValueText);
    final updated = await ref
        .read(currentGoalSubmissionControllerProvider.notifier)
        .submit(
          code: _goalCode,
          title: _titleController.text,
          targetValue: targetValue,
          targetUnit: _targetUnit,
          startsOn: _startsOn,
          endsOn: _endsOn,
          notes: _notesController.text,
        );

    if (!mounted || updated == null) {
      return;
    }

    await ref.read(currentGoalControllerProvider.notifier).reload();
    await ref.read(progressOverviewControllerProvider.notifier).reload();

    if (!mounted) {
      return;
    }
    context.go(AppRoutePaths.more);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTheme.of(context);
    final currentGoalState = ref.watch(currentGoalControllerProvider);
    final submissionState = ref.watch(currentGoalSubmissionControllerProvider);
    final isSubmitting = submissionState.isLoading;
    final submissionError = switch (submissionState) {
      AsyncError<void>(:final error) => moreErrorMessage(error),
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
                  'Goals settings',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Edit the current MVP goal so Progress and other summaries can reuse a stable target.',
                  style: theme.textTheme.bodyLarge,
                ),
                SizedBox(height: tokens.sectionSpacing),
                AppSecondaryButton(
                  label: 'Back to more',
                  onPressed: () => context.go(AppRoutePaths.more),
                ),
              ],
            ),
          ),
          SizedBox(height: tokens.sectionSpacing),
          currentGoalState.when(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            loading: () => const AppLoadingBlock(
              title: 'Loading goal settings',
              message: 'Pulling the current goal contract for editing.',
            ),
            error: (error, _) => AppErrorBlock(
              title: 'Could not load goal settings',
              message: moreErrorMessage(error),
              action: AppPrimaryButton(
                label: 'Retry',
                expand: true,
                onPressed: ref
                    .read(currentGoalControllerProvider.notifier)
                    .reload,
              ),
            ),
            data: (value) => _buildForm(
              context,
              theme,
              tokens,
              value,
              isSubmitting,
              submissionError,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    ThemeData theme,
    AppThemeTokens tokens,
    CurrentGoalData? goal,
    bool isSubmitting,
    String? submissionError,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (goal == null)
          Padding(
            padding: EdgeInsets.only(bottom: tokens.sectionSpacing),
            child: const AppEmptyStateBlock(
              title: 'No current goal yet',
              message:
                  'Use this screen to create the first current goal for the active user.',
            ),
          ),
        AppStandardCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: _goalCode,
                  decoration: const InputDecoration(labelText: 'Goal focus'),
                  items: _goalOptions
                      .map(
                        (code) => DropdownMenuItem(
                          value: code,
                          child: Text(_defaultTitleForCode(code)),
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
                            final previousCode = _goalCode;
                            final previousDefault = _defaultTitleForCode(previousCode);
                            _goalCode = value;
                            if (_titleController.text.trim().isEmpty ||
                                _titleController.text.trim() == previousDefault) {
                              _titleController.text = _defaultTitleForCode(value);
                            }
                          });
                        },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Goal title',
                  controller: _titleController,
                  validator: (value) => FormValidators.requiredText(
                    value,
                    label: 'Goal title',
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Target value',
                  controller: _targetValueController,
                  hintText: 'Optional',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => FormValidators.optionalDecimal(
                    value,
                    label: 'Target value',
                    min: 1,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _targetUnit,
                  decoration: const InputDecoration(labelText: 'Target unit'),
                  items: _unitOptions
                      .map(
                        (unit) => DropdownMenuItem(
                          value: unit,
                          child: Text(unit.isEmpty ? 'No unit' : unit),
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
                            _targetUnit = value;
                          });
                        },
                ),
                SizedBox(height: tokens.sectionSpacing),
                Text(
                  'Goal dates',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start ${formatMoreOptionalDate(_startsOn)}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'End ${formatMoreOptionalDate(_endsOn)}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    AppSecondaryButton(
                      label: 'Change start',
                      onPressed: isSubmitting ? null : _pickStartDate,
                    ),
                    if (_startsOn != null)
                      AppSecondaryButton(
                        label: 'Clear start',
                        onPressed: isSubmitting
                            ? null
                            : () => setState(() {
                                  _startsOn = null;
                                }),
                      ),
                    AppSecondaryButton(
                      label: 'Change end',
                      onPressed: isSubmitting ? null : _pickEndDate,
                    ),
                    if (_endsOn != null)
                      AppSecondaryButton(
                        label: 'Clear end',
                        onPressed: isSubmitting
                            ? null
                            : () => setState(() {
                                  _endsOn = null;
                                }),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Notes',
                  controller: _notesController,
                  hintText: 'Optional context',
                  maxLines: 3,
                ),
                if (submissionError != null) ...[
                  SizedBox(height: tokens.sectionSpacing),
                  AppErrorBlock(
                    title: 'Could not save goal',
                    message: submissionError,
                  ),
                ],
                if (isSubmitting) ...[
                  SizedBox(height: tokens.sectionSpacing),
                  const AppLoadingBlock(
                    title: 'Saving goal',
                    message:
                        'Updating the current goal and refreshing the related summaries.',
                  ),
                ],
                SizedBox(height: tokens.sectionSpacing),
                AppPrimaryButton(
                  label: 'Save goal',
                  expand: true,
                  onPressed: isSubmitting ? null : _submit,
                ),
                const SizedBox(height: 12),
                AppSecondaryButton(
                  label: 'Cancel',
                  expand: true,
                  onPressed: isSubmitting
                      ? null
                      : () => context.go(AppRoutePaths.more),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
