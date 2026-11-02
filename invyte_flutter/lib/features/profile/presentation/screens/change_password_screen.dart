import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/common.dart';
import '../providers/profile_providers.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(profileActionsProvider).changePassword(current: _current.text, next: _next.text);
      if (!mounted) return;
      showSnack(context, 'Password updated');
      context.pop();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change password')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            TextFormField(
              controller: _current,
              obscureText: true,
              validator: (v) => Validators.required(v, 'Current password'),
              decoration: const InputDecoration(hintText: 'Current password', prefixIcon: Icon(Icons.lock_outline_rounded)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _next,
              obscureText: true,
              validator: Validators.password,
              decoration: const InputDecoration(hintText: 'New password', prefixIcon: Icon(Icons.lock_reset_rounded)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirm,
              obscureText: true,
              validator: (v) => v != _next.text ? 'Passwords don\'t match' : null,
              decoration: const InputDecoration(hintText: 'Confirm new password', prefixIcon: Icon(Icons.lock_reset_rounded)),
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Update password', loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
