import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:memories_app/core/router/app_router.dart';
import 'package:memories_app/core/theme/app_theme.dart';
import 'package:memories_app/features/auth/presentation/providers/auth_provider.dart';

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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              _AppIcon(),
              const SizedBox(height: 20),
              Text(
                'remember together',
                style: AppTextStyles.tagline(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'plan, capture, and keep the moments that matter',
                style: AppTextStyles.bodySmall(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
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
              const SizedBox(height: 24),
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
          color: AppColors.grayLight,
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
                label: 'display name',
                controller: displayNameController,
                hint: 'your name',
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'display name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _LabeledField(
                label: 'handle',
                controller: handleController,
                hint: '@yourhandle',
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'handle is required';
                  }
                  final clean = v.trim().replaceFirst(RegExp(r'^@'), '');
                  if (!RegExp(r'^[a-z0-9_]{3,30}$').hasMatch(clean)) {
                    return 'lowercase letters, numbers, underscores only (3–30 chars)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
            ],
            _LabeledField(
              label: 'email',
              controller: emailController,
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'email is required';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
                  return 'enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _LabeledField(
              label: 'password',
              controller: passwordController,
              hint: isSignUp ? 'min. 8 characters' : 'your password',
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              suffixIcon: GestureDetector(
                onTap: onTogglePasswordVisibility,
                child: Icon(
                  obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: AppColors.textHint,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'password is required';
                if (isSignUp && v.length < 8) {
                  return 'password must be at least 8 characters';
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
                  : Text(isSignUp ? 'create account' : 'log in'),
            ),
            const SizedBox(height: 16),
            _OrDivider(),
            const SizedBox(height: 16),
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
        Text(label, style: AppTextStyles.uiLabel()),
        const SizedBox(height: 4),
        SizedBox(
          height: 34,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            obscureText: obscureText,
            style: AppTextStyles.uiInput(),
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
            'or',
            style: AppTextStyles.bodySmall(color: AppColors.textHint),
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
              color: AppColors.grayLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                'G',
                style: AppTextStyles.uiLabel(color: AppColors.textMuted)
                    .copyWith(fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'continue with Google',
            style: AppTextStyles.button(color: AppColors.text),
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTextStyles.bodySmall(color: AppColors.textMuted),
            children: [
              TextSpan(
                text: isSignUp
                    ? 'already have an account? '
                    : "don't have one? ",
              ),
              TextSpan(
                text: isSignUp ? 'log in' : 'sign up',
                style: AppTextStyles.bodySmall(color: AppColors.teal).copyWith(
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.teal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
