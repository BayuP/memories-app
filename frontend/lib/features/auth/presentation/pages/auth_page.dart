import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memories_app/core/router/app_router.dart';
import 'package:memories_app/core/theme/app_theme.dart';
import 'package:memories_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:memories_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:memories_app/features/trips/presentation/providers/trips_provider.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  bool _isSignUp = true;

  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _handleController = TextEditingController();
  final _displayNameController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _handleController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final notifier = ref.read(authProvider.notifier);

    if (_isSignUp) {
      await notifier.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        handle: _handleController.text.trim().replaceFirst(RegExp(r'^@'), ''),
        displayName: _displayNameController.text.trim(),
      );
    } else {
      await notifier.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }

    if (!mounted) return;

    final authState = ref.read(authProvider);
    authState.whenOrNull(
      error: (error, _) {
        final message = _extractErrorMessage(error);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
      data: (state) {
        if (state.status == AuthStatus.authenticated) {
          ref.invalidate(tripsProvider);
          ref.invalidate(currentUserIdProvider);
          ref.invalidate(profileProvider);
          context.go(AppRoutes.home);
        }
      },
    );
  }

  String _extractErrorMessage(Object error) {
    final str = error.toString();
    // ApiException(code): message
    final match = RegExp(r'ApiException\([^)]+\):\s*(.+)').firstMatch(str);
    return match?.group(1) ?? str;
  }

  void _onGoogleTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google sign-in coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authProvider);
    final isLoading = authAsync.isLoading;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              _AppIcon(),
              const SizedBox(height: 20),
              Text(
                'Remember together',
                style: AppTextStyles.displaySmall.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Plan, capture, and keep the moments that matter',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              _AuthCard(
                isSignUp: _isSignUp,
                formKey: _formKey,
                emailController: _emailController,
                passwordController: _passwordController,
                handleController: _handleController,
                displayNameController: _displayNameController,
                obscurePassword: _obscurePassword,
                onTogglePasswordVisibility: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                isLoading: isLoading,
                onSubmit: _submit,
                onGoogleTap: _onGoogleTap,
              ),
              const SizedBox(height: 20),
              _ToggleModeButton(
                isSignUp: _isSignUp,
                onTap: _toggleMode,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _AppIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Center(
          child: Text(
            '\u{1F4F8}',
            style: TextStyle(fontSize: 26),
          ),
        ),
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.isSignUp,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.handleController,
    required this.displayNameController,
    required this.obscurePassword,
    required this.onTogglePasswordVisibility,
    required this.isLoading,
    required this.onSubmit,
    required this.onGoogleTap,
  });

  final bool isSignUp;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController handleController;
  final TextEditingController displayNameController;
  final bool obscurePassword;
  final VoidCallback onTogglePasswordVisibility;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onGoogleTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isSignUp) ...[
              _LabeledField(
                label: 'Display name',
                controller: displayNameController,
                hint: 'Your name',
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Display name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _LabeledField(
                label: 'Handle',
                controller: handleController,
                hint: '@yourhandle',
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Handle is required';
                  }
                  final clean = v.trim().replaceFirst(RegExp(r'^@'), '');
                  if (!RegExp(r'^[a-z0-9_]{3,30}$').hasMatch(clean)) {
                    return 'Lowercase letters, numbers, underscores only (3-30 chars)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
            ],
            _LabeledField(
              label: 'Email',
              controller: emailController,
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _LabeledField(
              label: 'Password',
              controller: passwordController,
              hint: isSignUp ? 'Min. 8 characters' : 'Your password',
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              suffixIcon: GestureDetector(
                onTap: onTogglePasswordVisibility,
                child: Icon(
                  obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (isSignUp && v.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              child: isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : Text(isSignUp ? 'Create Account' : 'Log In'),
            ),
            const SizedBox(height: AppSpacing.md),
            _OrDivider(),
            const SizedBox(height: AppSpacing.md),
            _GoogleButton(onTap: onGoogleTap),
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelSmall),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 34,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            obscureText: obscureText,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: suffixIcon,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 34,
              ),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Or',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Simple "G" lettermark since we're not adding an svg asset dep
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                'G',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Continue with Google',
            style: AppTextStyles.button.copyWith(color: AppColors.text),
          ),
        ],
      ),
    );
  }
}

class _ToggleModeButton extends StatelessWidget {
  const _ToggleModeButton({
    required this.isSignUp,
    required this.onTap,
  });

  final bool isSignUp;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            children: [
              TextSpan(
                text: isSignUp
                    ? 'Already have an account? '
                    : "Don't have one? ",
              ),
              TextSpan(
                text: isSignUp ? 'Log in' : 'Sign up',
                style: AppTextStyles.bodySmall
                    .copyWith(
                      color: AppColors.accentGreen,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.accentGreen,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
