import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/app_api_client.dart';
import '../../../core/presentation/widgets/widgets.dart';
import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/validation/form_validators.dart';
import '../../onboarding/application/onboarding_controller.dart';
import '../application/auth_session.dart';

class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  ConsumerState<PasswordResetScreen> createState() =>
      _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final _requestFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _tokenController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  bool _isRequesting = false;
  bool _isResetting = false;
  bool _showResetForm = false;
  String? _requestError;
  String? _requestMessage;
  String? _previewToken;
  int? _tokenExpiresIn;
  String? _resetError;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _tokenController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _tokenHelperText() {
    if (_tokenExpiresIn == null) {
      return null;
    }

    final expiresIn = _tokenExpiresIn!;
    if (expiresIn % 3600 == 0) {
      final hours = expiresIn ~/ 3600;
      return 'Tokens currently expire after $hours hour${hours == 1 ? '' : 's'}.';
    }
    if (expiresIn % 60 == 0) {
      final minutes = expiresIn ~/ 60;
      return 'Tokens currently expire after $minutes minute${minutes == 1 ? '' : 's'}.';
    }
    return 'Tokens currently expire after $expiresIn seconds.';
  }

  void _seedOnboardingForSession(AuthSessionState session) {
    if (session.needsOnboarding) {
      ref.read(onboardingControllerProvider.notifier).seedFromSignup(
            email: session.email ?? _emailController.text.trim(),
            displayName: session.displayName ?? 'User',
          );
      return;
    }

    ref.read(onboardingControllerProvider.notifier).seedFromAuthenticatedSession(
          email: session.email ?? _emailController.text.trim(),
          displayName: session.displayName,
        );
  }

  Future<void> _requestReset() async {
    if (!_requestFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isRequesting = true;
      _requestError = null;
      _requestMessage = null;
    });

    try {
      final response = await ref
          .read(authSessionProvider.notifier)
          .requestPasswordReset(email: _emailController.text.trim());
      if (!mounted) {
        return;
      }
      setState(() {
        _requestMessage = response.detail;
        _previewToken = response.previewToken;
        _tokenExpiresIn = response.expiresIn;
        _showResetForm = true;
        _resetError = null;
        if (response.previewToken != null && response.previewToken!.trim().isNotEmpty) {
          _tokenController.text = response.previewToken!;
        }
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _requestError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _requestError = 'Could not prepare a password reset right now. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
      }
    }
  }

  Future<void> _confirmReset() async {
    if (!_resetFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isResetting = true;
      _resetError = null;
    });

    try {
      final session = await ref.read(authSessionProvider.notifier).resetPassword(
            token: _tokenController.text.trim(),
            newPassword: _newPasswordController.text,
          );
      _seedOnboardingForSession(session);

      if (!mounted) {
        return;
      }
      context.go(AppRoutePaths.welcome);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _resetError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _resetError = 'Could not reset the password right now. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResetting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTheme.of(context);
    final isBusy = _isRequesting || _isResetting;

    return AppScaffold(
      appBar: const AppTopAppBar(title: 'Password reset'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppStandardCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recover account access',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Request a reset token for your email address, then choose a new password. In local development the backend can return a preview token directly here.',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            SizedBox(height: tokens.sectionSpacing),
            AppStandardCard(
              child: Form(
                key: _requestFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      label: 'Email',
                      hintText: 'name@example.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      validator: FormValidators.email,
                      onFieldSubmitted: (_) => _requestReset(),
                    ),
                    if (_requestError != null) ...[
                      SizedBox(height: tokens.sectionSpacing),
                      AppErrorBlock(
                        title: 'Could not request a reset',
                        message: _requestError!,
                      ),
                    ],
                    if (_isRequesting) ...[
                      SizedBox(height: tokens.sectionSpacing),
                      const AppLoadingBlock(
                        title: 'Preparing reset instructions',
                        message:
                            'Checking the account details and preparing a password reset challenge.',
                      ),
                    ],
                    const SizedBox(height: 24),
                    AppPrimaryButton(
                      label: 'Request reset token',
                      expand: true,
                      onPressed: isBusy ? null : _requestReset,
                    ),
                  ],
                ),
              ),
            ),
            if (_requestMessage != null) ...[
              SizedBox(height: tokens.sectionSpacing),
              AppEmptyStateBlock(
                title: 'Reset instructions prepared',
                message: _requestMessage!,
              ),
            ],
            if (_previewToken != null && _previewToken!.trim().isNotEmpty) ...[
              SizedBox(height: tokens.sectionSpacing),
              AppStandardCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Local preview token',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SelectableText(_previewToken!),
                    if (_tokenHelperText() != null) ...[
                      const SizedBox(height: 12),
                      Text(_tokenHelperText()!, style: theme.textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
            ],
            if (_showResetForm) ...[
              SizedBox(height: tokens.sectionSpacing),
              AppStandardCard(
                child: Form(
                  key: _resetFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose a new password',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Reset token',
                        hintText: 'Paste the token you received',
                        helperText: _tokenHelperText(),
                        controller: _tokenController,
                        textInputAction: TextInputAction.next,
                        validator: FormValidators.requiredTextToken,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'New password',
                        hintText: 'At least 8 characters with a letter and number',
                        controller: _newPasswordController,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        validator: FormValidators.securePassword,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Confirm new password',
                        controller: _confirmPasswordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        validator: (value) => FormValidators.confirmPassword(
                          value,
                          password: _newPasswordController.text,
                        ),
                        onFieldSubmitted: (_) => _confirmReset(),
                      ),
                      if (_resetError != null) ...[
                        SizedBox(height: tokens.sectionSpacing),
                        AppErrorBlock(
                          title: 'Could not reset password',
                          message: _resetError!,
                        ),
                      ],
                      if (_isResetting) ...[
                        SizedBox(height: tokens.sectionSpacing),
                        const AppLoadingBlock(
                          title: 'Resetting password',
                          message:
                              'Saving the new password, rotating the auth session, and signing you back in.',
                        ),
                      ],
                      const SizedBox(height: 24),
                      AppPrimaryButton(
                        label: 'Reset password',
                        expand: true,
                        onPressed: isBusy ? null : _confirmReset,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            SizedBox(height: tokens.sectionSpacing),
            AppSecondaryButton(
              label: 'Back to login',
              expand: true,
              onPressed: isBusy ? null : () => context.go(AppRoutePaths.login),
            ),
            const SizedBox(height: 12),
            AppSecondaryButton(
              label: 'Back to welcome',
              expand: true,
              onPressed: isBusy ? null : () => context.go(AppRoutePaths.welcome),
            ),
          ],
        ),
      ),
    );
  }
}
