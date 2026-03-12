import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/presentation/widgets/widgets.dart';
import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/validation/form_validators.dart';
import '../application/auth_session.dart';
import '../../onboarding/application/onboarding_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

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

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    ref.read(authSessionProvider.notifier).previewLogin(email: email);
    final session = ref.read(authSessionProvider);
    ref.read(onboardingControllerProvider.notifier).loadReturningMemberPreview(
          email: session.email ?? email,
          displayName: session.displayName,
        );

    if (!mounted) {
      return;
    }
    context.go(AppRoutePaths.today);
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
                    'This is a preview login flow. It validates form input and unlocks the shell without calling a real auth provider yet.',
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
                    const SizedBox(height: 24),
                    AppPrimaryButton(
                      label: 'Continue',
                      expand: true,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 12),
                    AppSecondaryButton(
                      label: 'Create account',
                      expand: true,
                      onPressed: () => context.go(AppRoutePaths.signup),
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
              title: 'No backend auth yet',
              message:
                  'Passwords stay local to the preview form in this milestone. Real session handling and token exchange come later.',
            ),
          ],
        ),
      ),
    );
  }
}