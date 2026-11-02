import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/common.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: ref.read(currentUserProvider)?.fullName);
  late final _bio = TextEditingController(text: ref.read(currentUserProvider)?.bio);
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(profileActionsProvider).updateProfile(
            fullName: _name.text,
            bio: _bio.text.trim().isEmpty ? null : _bio.text,
          );
      if (!mounted) return;
      showSnack(context, 'Profile updated');
      context.pop();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(currentUserProvider)?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            TextFormField(
              initialValue: email,
              enabled: false,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.alternate_email_rounded)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              validator: (v) => Validators.required(v, 'Name'),
              decoration: const InputDecoration(hintText: 'Full name', prefixIcon: Icon(Icons.person_outline_rounded)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _bio,
              minLines: 3,
              maxLines: 5,
              maxLength: 160,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'A short bio'),
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Save changes', loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
