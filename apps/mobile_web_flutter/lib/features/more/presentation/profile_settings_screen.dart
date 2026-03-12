import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/widgets/widgets.dart';
import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/validation/form_validators.dart';
import '../../auth/application/auth_session.dart';
import '../application/current_user_controller.dart';
import '../application/current_user_submission_controller.dart';
import '../domain/more_models.dart';
import 'more_presentation_utils.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _heightController = TextEditingController();
  final _bioController = TextEditingController();

  ProviderSubscription<AsyncValue<CurrentUserData>>? _currentUserSubscription;
  DateTime? _birthDate;
  bool _initializedForm = false;

  @override
  void initState() {
    super.initState();
    _currentUserSubscription = ref.listenManual<AsyncValue<CurrentUserData>>(
      currentUserControllerProvider,
      (previous, next) {
        if (_initializedForm) {
          return;
        }
        next.whenData(
          (user) => _seedForm(
            user,
            notify: previous != null,
          ),
        );
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _currentUserSubscription?.close();
    _emailController.dispose();
    _displayNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _heightController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _seedForm(CurrentUserData user, {required bool notify}) {
    void apply() {
      _emailController.text = user.email;
      _displayNameController.text = user.profile?.displayName ?? '';
      _firstNameController.text = user.profile?.firstName ?? '';
      _lastNameController.text = user.profile?.lastName ?? '';
      _heightController.text = user.profile?.heightCm == null
          ? ''
          : formatMoreNumber(user.profile!.heightCm!);
      _bioController.text = user.profile?.bio ?? '';
      _birthDate = user.profile?.birthDate;
      _initializedForm = true;
    }

    if (!notify || !mounted) {
      apply();
      return;
    }

    setState(apply);
  }

  Future<void> _pickBirthDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(1995, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate == null) {
      return;
    }

    setState(() {
      _birthDate = pickedDate;
    });
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final heightText = _heightController.text.trim();
    final heightCm = heightText.isEmpty ? null : double.parse(heightText);
    final updated = await ref
        .read(currentUserSubmissionControllerProvider.notifier)
        .submit(
          email: _emailController.text,
          displayName: _displayNameController.text,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          birthDate: _birthDate,
          heightCm: heightCm,
          bio: _bioController.text,
        );

    if (!mounted || updated == null) {
      return;
    }

    ref.read(authSessionProvider.notifier).syncProfile(
          email: updated.email,
          displayName: updated.profile?.displayName,
        );
    await ref.read(currentUserControllerProvider.notifier).reload();

    if (!mounted) {
      return;
    }
    context.go(AppRoutePaths.more);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTheme.of(context);
    final currentUserState = ref.watch(currentUserControllerProvider);
    final submissionState = ref.watch(currentUserSubmissionControllerProvider);
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
                  'Profile settings',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Update the lightweight profile fields that drive the More home summary and the authenticated account profile.',
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
          currentUserState.when(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            loading: () => const AppLoadingBlock(
              title: 'Loading profile settings',
              message: 'Pulling the current profile fields for editing.',
            ),
            error: (error, _) => AppErrorBlock(
              title: 'Could not load profile settings',
              message: moreErrorMessage(error),
              action: AppPrimaryButton(
                label: 'Retry',
                expand: true,
                onPressed: ref
                    .read(currentUserControllerProvider.notifier)
                    .reload,
              ),
            ),
            data: (_) => _buildForm(
              context,
              theme,
              tokens,
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
    bool isSubmitting,
    String? submissionError,
  ) {
    return AppStandardCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: 'Email',
              controller: _emailController,
              validator: FormValidators.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Display name',
              controller: _displayNameController,
              hintText: 'Optional public label',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'First name',
                    controller: _firstNameController,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Last name',
                    controller: _lastNameController,
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.sectionSpacing),
            Text(
              'Birth date',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formatMoreOptionalDate(_birthDate),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AppSecondaryButton(
                  label: 'Change date',
                  onPressed: isSubmitting ? null : _pickBirthDate,
                ),
                if (_birthDate != null)
                  AppSecondaryButton(
                    label: 'Clear date',
                    onPressed: isSubmitting
                        ? null
                        : () => setState(() {
                              _birthDate = null;
                            }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Height (cm)',
              controller: _heightController,
              hintText: 'Optional',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) => FormValidators.optionalDecimal(
                value,
                label: 'Height',
                min: 1,
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Bio',
              controller: _bioController,
              hintText: 'Optional short note',
              maxLines: 3,
            ),
            if (submissionError != null) ...[
              SizedBox(height: tokens.sectionSpacing),
              AppErrorBlock(
                title: 'Could not save profile',
                message: submissionError,
              ),
            ],
            if (isSubmitting) ...[
              SizedBox(height: tokens.sectionSpacing),
              const AppLoadingBlock(
                title: 'Saving profile',
                message:
                    'Updating the current user profile and refreshing the More summary.',
              ),
            ],
            SizedBox(height: tokens.sectionSpacing),
            AppPrimaryButton(
              label: 'Save profile',
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
    );
  }
}

