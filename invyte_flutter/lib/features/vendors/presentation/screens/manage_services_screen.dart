import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/vendor.dart';
import '../providers/vendor_providers.dart';
import '../widgets/vendor_cards.dart';

class ManageServicesScreen extends ConsumerWidget {
  const ManageServicesScreen({super.key});

  Future<void> _delete(BuildContext context, WidgetRef ref, VendorService service) async {
    final ok = await confirmAction(
      context,
      title: 'Remove service?',
      message: '"${service.name}" will no longer be bookable.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!ok) return;
    try {
      await ref.read(vendorRepositoryProvider).deleteService(service.id);
      ref.invalidate(myServicesProvider);
      if (context.mounted) showSnack(context, 'Service removed');
    } catch (e) {
      if (context.mounted) showErrorSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(myServicesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My services')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showServiceEditor(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add service'),
      ),
      body: AsyncValueView(
        value: services,
        onRetry: () => ref.invalidate(myServicesProvider),
        data: (List<VendorService> items) => RefreshIndicator(
          onRefresh: () => ref.refresh(myServicesProvider.future),
          child: items.isEmpty
              ? ListView(children: [
                  EmptyState(
                    icon: Icons.design_services_rounded,
                    title: 'List your first service',
                    message: 'Services are what customers book. Add pricing and a short description.',
                    actionLabel: 'Add service',
                    onAction: () => showServiceEditor(context),
                  ),
                ])
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final s = items[i];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Icon(categoryIcon(s.categoryName), color: AppColors.primary),
                        ),
                        title: Text(s.name, style: Theme.of(context).textTheme.titleSmall),
                        subtitle: Text('${Fmt.money(s.basePrice)} ${s.unitLabel}'
                            '${s.categoryName == null ? '' : ' · ${s.categoryName}'}'),
                        onTap: () => showServiceEditor(context, existing: s),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) =>
                              v == 'edit' ? showServiceEditor(context, existing: s) : _delete(context, ref, s),
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Remove')),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

Future<void> showServiceEditor(BuildContext context, {VendorService? existing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ServiceEditor(existing: existing),
  );
}

class _ServiceEditor extends ConsumerStatefulWidget {
  const _ServiceEditor({this.existing});

  final VendorService? existing;

  @override
  ConsumerState<_ServiceEditor> createState() => _ServiceEditorState();
}

class _ServiceEditorState extends ConsumerState<_ServiceEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _description = TextEditingController(text: widget.existing?.description);
  late final _price = TextEditingController(text: widget.existing?.basePrice.toStringAsFixed(0));
  late int? _categoryId = widget.existing?.categoryId;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final draft = ServiceDraft(
      categoryId: _categoryId!,
      name: _name.text.trim(),
      description: _description.text.trim().isEmpty ? null : _description.text.trim(),
      basePrice: double.parse(_price.text.trim()),
    );
    try {
      final repo = ref.read(vendorRepositoryProvider);
      widget.existing == null ? await repo.createService(draft) : await repo.updateService(widget.existing!.id, draft);
      ref.invalidate(myServicesProvider);
      if (!mounted) return;
      Navigator.pop(context);
      showSnack(context, widget.existing == null ? 'Service added' : 'Service updated');
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? const <ServiceCategory>[];
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.existing == null ? 'New service' : 'Edit service',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 18),
              DropdownButtonFormField<int>(
                initialValue: categories.any((c) => c.id == _categoryId) ? _categoryId : null,
                isExpanded: true,
                validator: (v) => v == null ? 'Choose a category' : null,
                decoration: const InputDecoration(hintText: 'Category', prefixIcon: Icon(Icons.category_outlined)),
                items: [for (final c in categories) DropdownMenuItem(value: c.id, child: Text(c.name))],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                validator: (v) => Validators.required(v, 'Service name'),
                decoration: const InputDecoration(hintText: 'Service name'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => Validators.positiveNumber(v, 'Price'),
                decoration: const InputDecoration(hintText: 'Base price', prefixIcon: Icon(Icons.sell_outlined)),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _description,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: "What's included?"),
              ),
              const SizedBox(height: 22),
              PrimaryButton(label: 'Save service', loading: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
