import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/widgets/widgets.dart';
import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/validation/form_validators.dart';
import '../application/auth_session.dart';
import '../../onboarding/application/onboarding_controller.dart';

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

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final displayName = _displayNameController.text.trim();
    final email = _emailController.text.trim();

    ref.read(authSessionProvider.notifier).previewSignup(
          email: email,
          displayName: displayName,
        );
    ref.read(onboardingControllerProvider.notifier).seedFromSignup(
          email: email,
          displayName: displayName,
        );

    if (!mounted) {
      return;
    }
    context.go(AppRoutePaths.onboardingGoal);
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
                    'Create your preview account',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This foundation captures a name, email, and password shape, then moves straight into onboarding without a real backend signup call yet.',
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
                    const SizedBox(height: 24),
                    AppPrimaryButton(
                      label: 'Continue to onboarding',
                      expand: true,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 12),
                    AppSecondaryButton(
                      label: 'Already have an account?',
                      expand: true,
                      onPressed: () => context.go(AppRoutePaths.login),
                    ),
                    const SizedBox(height: 12),
                    AppSecondaryButton(
                      label: 'Back to welcome',
                      expand: true,
                      onPressed: () => context.go(AppRoutePaths.welcome),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: tokens.sectionSpacing),
            const AppEmptyStateBlock(
              title: 'Onboarding comes next',
              message:
                  'Goal, stats, activity, and target selections are stored locally for now so the full vertical slice can be built on top later.',
            ),
          ],
        ),
      ),
    );
  }
}