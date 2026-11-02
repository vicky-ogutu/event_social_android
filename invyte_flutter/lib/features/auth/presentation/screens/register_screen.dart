import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/common.dart';
import '../../domain/entities/user.dart';
import '../providers/auth_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  UserRole _role = UserRole.consumer;
  bool _obscure = true;
  bool _agreed = false;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      showSnack(context, 'Please accept the terms to continue.', error: true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final pendingEmail = await ref.read(authControllerProvider.notifier).register(
            fullName: _name.text,
            email: _email.text,
            password: _password.text,
            role: _role,
          );
      if (pendingEmail != null && mounted) {
        context.pushReplacement(Routes.verifyEmail(pendingEmail));
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
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
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            children: [
              Text('Create your account', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                'Join thousands of hosts and vendors making moments happen.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              Text('I want to…', style: theme.textTheme.titleSmall),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _RoleCard(
                      icon: Icons.celebration_rounded,
                      title: 'Host events',
                      subtitle: 'Plan & book vendors',
                      selected: _role == UserRole.consumer,
                      onTap: () => setState(() => _role = UserRole.consumer),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RoleCard(
                      icon: Icons.storefront_rounded,
                      title: 'Offer services',
                      subtitle: 'Get booked as a vendor',
                      selected: _role == UserRole.vendor,
                      onTap: () => setState(() => _role = UserRole.vendor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: (v) => Validators.required(v, 'Full name'),
                decoration: const InputDecoration(hintText: 'Full name', prefixIcon: Icon(Icons.person_outline_rounded)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: Validators.email,
                decoration: const InputDecoration(hintText: 'Email address', prefixIcon: Icon(Icons.alternate_email_rounded)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.newPassword],
                validator: Validators.password,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'Password (8+ characters)',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _agreed,
                onChanged: (v) => setState(() => _agreed = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.primary,
                title: Text(
                  'I agree to the Terms of Service and Privacy Policy',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(label: 'Create account', loading: _loading, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary.withValues(alpha: 0.08) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? AppColors.primary : theme.colorScheme.outline, width: selected ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: selected ? AppColors.primary : theme.colorScheme.onSurfaceVariant),
                  const Spacer(),
                  Icon(
                    selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                    color: selected ? AppColors.primary : theme.colorScheme.outline,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(title, style: theme.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
