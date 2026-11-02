import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/common.dart';
import '../providers/auth_providers.dart';
import '../widgets/code_field.dart';

/// Step 1: request a reset code by email.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.email});

  final String? email;

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  bool _sending = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    // Password reset always talks to the real API.
    ref.read(demoModeProvider.notifier).set(false);
    try {
      final email = _email.text.trim();
      await ref.read(authRepositoryProvider).requestPasswordReset(email);
      if (mounted) context.pushReplacement(Routes.resetPassword(email));
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              const _Badge(icon: Icons.lock_reset_rounded),
              const SizedBox(height: 24),
              Text('Forgot your password?', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                "Enter the email you signed up with and we'll send you a 6-digit code to reset it.",
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _email,
                autofocus: widget.email == null,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: Validators.email,
                onFieldSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  hintText: 'Email address',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(label: 'Send reset code', loading: _sending, onPressed: _send),
            ],
          ),
        ),
      ),
    );
  }
}

/// Step 2: enter the code and a new password.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _saving = false;

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (_code.text.length != 6) {
      showSnack(context, 'Enter the 6-digit code from your email.', error: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            email: widget.email,
            code: _code.text,
            newPassword: _password.text,
          );
      if (!mounted) return;
      showSnack(context, 'Password updated. Sign in with your new password.');
      context.go(Routes.login);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resend() async {
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(widget.email);
      if (mounted) showSnack(context, 'A new code is on its way');
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              const _Badge(icon: Icons.password_rounded),
              const SizedBox(height: 24),
              Text('Choose a new password', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(children: [
                  const TextSpan(text: 'If an account exists for '),
                  TextSpan(text: widget.email, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const TextSpan(text: ", we've emailed it a 6-digit code."),
                ]),
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              CodeField(controller: _code, enabled: !_saving),
              Center(child: ResendCodeButton(onResend: _resend)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.newPassword],
                validator: Validators.password,
                decoration: InputDecoration(
                  hintText: 'New password (8+ characters)',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirm,
                obscureText: _obscure,
                validator: (v) => v != _password.text ? "Passwords don't match" : null,
                onFieldSubmitted: (_) => _reset(),
                decoration: const InputDecoration(
                  hintText: 'Confirm new password',
                  prefixIcon: Icon(Icons.lock_reset_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'For your security, this signs you out on all other devices.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              PrimaryButton(label: 'Update password', loading: _saving, onPressed: _reset),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: AppColors.primary, size: 34),
      ),
    );
  }
}
