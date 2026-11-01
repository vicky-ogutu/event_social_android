import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/vendor.dart';
import '../providers/vendor_providers.dart';

class BusinessProfileScreen extends ConsumerWidget {
  const BusinessProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myVendorProfileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Business profile')),
      body: AsyncValueView(
        value: profile,
        onRetry: () => ref.invalidate(myVendorProfileProvider),
        data: (VendorProfile? p) => _BusinessForm(initial: p),
      ),
    );
  }
}

class _BusinessForm extends ConsumerStatefulWidget {
  const _BusinessForm({this.initial});

  final VendorProfile? initial;

  @override
  ConsumerState<_BusinessForm> createState() => _BusinessFormState();
}

class _BusinessFormState extends ConsumerState<_BusinessForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.businessName);
  late final _address = TextEditingController(text: widget.initial?.address);
  late final _phone = TextEditingController(text: widget.initial?.phone);
  late final _description = TextEditingController(text: widget.initial?.description);
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _address, _phone, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(vendorRepositoryProvider).saveProfile(
            VendorProfileDraft(
              businessName: _name.text.trim(),
              address: _address.text.trim(),
              phone: _phone.text.trim(),
              description: _description.text.trim().isEmpty ? null : _description.text.trim(),
            ),
            exists: widget.initial != null,
          );
      ref.invalidate(myVendorProfileProvider);
      if (!mounted) return;
      showSnack(context, 'Business profile saved');
      context.pop();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          if (widget.initial == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                'Tell customers about your business. This appears on your public vendor page.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            validator: (v) => Validators.required(v, 'Business name'),
            decoration: const InputDecoration(hintText: 'Business name', prefixIcon: Icon(Icons.storefront_outlined)),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _address,
            textCapitalization: TextCapitalization.words,
            validator: (v) => Validators.required(v, 'Address'),
            decoration: const InputDecoration(hintText: 'Business address', prefixIcon: Icon(Icons.place_outlined)),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            validator: (v) => Validators.required(v, 'Phone'),
            decoration: const InputDecoration(hintText: 'Phone number', prefixIcon: Icon(Icons.call_outlined)),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _description,
            minLines: 4,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'What makes your service special?'),
          ),
          const SizedBox(height: 28),
          PrimaryButton(label: 'Save', loading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}
