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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  bool _isSubmitting = false;
  String? _submissionError;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

    try {
      final session = await ref.read(authSessionProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (session.needsOnboarding) {
        ref.read(onboardingControllerProvider.notifier).seedFromSignup(
              email: session.email ?? _emailController.text.trim(),
              displayName: session.displayName ?? 'User',
            );
      } else {
        ref.read(onboardingControllerProvider.notifier).seedFromAuthenticatedSession(
              email: session.email ?? _emailController.text.trim(),
              displayName: session.displayName,
            );
      }

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
        _submissionError = 'Could not log in right now. Please try again.';
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
      appBar: const AppTopAppBar(title: 'Login'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppStandardCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sign in with the account you created to reopen your personal dashboard, logs, and settings.',
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
                      textInputAction: TextInputAction.done,
                      validator: FormValidators.password,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_submissionError != null) ...[
                      SizedBox(height: tokens.sectionSpacing),
                      AppErrorBlock(
                        title: 'Login failed',
                        message: _submissionError!,
                      ),
                    ],
                    if (_isSubmitting) ...[
                      SizedBox(height: tokens.sectionSpacing),
                      const AppLoadingBlock(
                        title: 'Signing in',
                        message:
                            'Checking your credentials and restoring your account session.',
                      ),
                    ],
                    const SizedBox(height: 24),
                    AppPrimaryButton(
                      label: 'Continue',
                      expand: true,
                      onPressed: _isSubmitting ? null : _submit,
                    ),
                    const SizedBox(height: 12),
                    AppSecondaryButton(
                      label: 'Create account',
                      expand: true,
                      onPressed: _isSubmitting
                          ? null
                          : () => context.go(AppRoutePaths.signup),
                    ),
                    const SizedBox(height: 12),
                    AppSecondaryButton(
                      label: 'Forgot password',
                      expand: true,
                      onPressed: _isSubmitting
                          ? null
                          : () => context.go(AppRoutePaths.forgotPassword),
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
          ],
        ),
      ),
    );
  }
}


