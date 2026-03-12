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

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  bool _isSubmitting = false;
  String? _submissionError;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });

    final displayName = _displayNameController.text.trim();
    final email = _emailController.text.trim();

    try {
      await ref.read(authSessionProvider.notifier).signup(
            displayName: displayName,
            email: email,
            password: _passwordController.text,
          );
      ref.read(onboardingControllerProvider.notifier).seedFromSignup(
            email: email,
            displayName: displayName,
          );

      if (!mounted) {
        return;
      }
      context.go(AppRoutePaths.welcome);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submissionError = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submissionError = 'Could not create your account right now. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTheme.of(context);

    return AppScaffold(
      appBar: const AppTopAppBar(title: 'Signup'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppStandardCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create your account',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Create a real account to unlock your own data and continue through the existing onboarding flow.',
                    style: theme.textTheme.bodyLarge,
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
                    AppTextField(
                      label: 'Display name',
                      hintText: 'Alex Morgan',
                      controller: _displayNameController,
                      textInputAction: TextInputAction.next,
                      validator: (value) => FormValidators.requiredText(
                        value,
                        label: 'Display name',
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Email',
                      hintText: 'name@example.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: FormValidators.email,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Password',
                      hintText: 'At least 8 characters',
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      validator: FormValidators.password,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Confirm password',
                      controller: _confirmPasswordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      validator: (value) => FormValidators.confirmPassword(
                        value,
                        password: _passwordController.text,
                      ),
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_submissionError != null) ...[
                      SizedBox(height: tokens.sectionSpacing),
                      AppErrorBlock(
                        title: 'Signup failed',
                        message: _submissionError!,
                      ),
                    ],
                    if (_isSubmitting) ...[
                      SizedBox(height: tokens.sectionSpacing),
                      const AppLoadingBlock(
                        title: 'Creating account',
                        message:
                            'Saving your account, starting a secure session, and preparing onboarding.',
                      ),
                    ],
                    const SizedBox(height: 24),
                    AppPrimaryButton(
                      label: 'Continue to onboarding',
                      expand: true,
                      onPressed: _isSubmitting ? null : _submit,
                    ),
                    const SizedBox(height: 12),
                    AppSecondaryButton(
                      label: 'Already have an account?',
                      expand: true,
                      onPressed: _isSubmitting
                          ? null
                          : () => context.go(AppRoutePaths.login),
                    ),
                    const SizedBox(height: 12),
                    AppSecondaryButton(
                      label: 'Back to welcome',
                      expand: true,
                      onPressed: _isSubmitting
                          ? null
                          : () => context.go(AppRoutePaths.welcome),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: tokens.sectionSpacing),
            const AppEmptyStateBlock(
              title: 'Onboarding comes next',
              message:
                  'Goal, stats, activity, and target selections still use the existing MVP onboarding flow after signup completes.',
            ),
          ],
        ),
      ),
    );
  }
}
