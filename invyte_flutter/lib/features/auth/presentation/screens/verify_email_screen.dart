import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/common.dart';
import '../providers/auth_providers.dart';
import '../widgets/code_field.dart';

/// Enter the 6-digit code emailed at sign-up. Success signs the user in and
/// the router moves them to their home screen.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _code = TextEditingController();
  bool _verifying = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_code.text.length != 6 || _verifying) return;
    FocusScope.of(context).unfocus();
    setState(() => _verifying = true);
    try {
      await ref.read(authControllerProvider.notifier).verifyEmail(email: widget.email, code: _code.text);
    } catch (e) {
      _code.clear();
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    try {
      await ref.read(authRepositoryProvider).resendVerification(widget.email);
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            const _Badge(icon: Icons.mark_email_unread_rounded),
            const SizedBox(height: 24),
            Text('Check your email', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'We sent a 6-digit code to '),
                TextSpan(text: widget.email, style: const TextStyle(fontWeight: FontWeight.w700)),
                const TextSpan(text: '. Enter it below to confirm your account.'),
              ]),
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            CodeField(controller: _code, enabled: !_verifying, onCompleted: (_) => _verify()),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Verify email', loading: _verifying, onPressed: _verify),
            const SizedBox(height: 8),
            Center(child: ResendCodeButton(onResend: _resend)),
            const SizedBox(height: 8),
            Text(
              "Can't find it? Check your spam folder. Codes expire after 15 minutes.",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
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
