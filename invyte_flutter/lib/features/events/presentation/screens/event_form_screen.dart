import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/image_picking.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/event.dart';
import '../providers/event_providers.dart';

/// Create a new event, or edit an existing one when [eventId] is given.
class EventFormScreen extends ConsumerWidget {
  const EventFormScreen({super.key, this.eventId});

  final int? eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = eventId;
    if (id == null) return const _EventForm();
    final event = ref.watch(eventDetailProvider(id));
    return AsyncValueView(
      value: event,
      onRetry: () => ref.invalidate(eventDetailProvider(id)),
      loading: const Scaffold(body: Center(child: CircularProgressIndicator())),
      data: (Event e) => _EventForm(initial: e),
    );
  }
}

class _EventForm extends ConsumerStatefulWidget {
  const _EventForm({this.initial});

  final Event? initial;

  @override
  ConsumerState<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends ConsumerState<_EventForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _description = TextEditingController(text: widget.initial?.description);
  late final _venue = TextEditingController(text: widget.initial?.venue);
  late final _guests = TextEditingController(text: widget.initial?.expectedAttendees?.toString());
  late final _budget = TextEditingController(text: widget.initial?.budget?.toStringAsFixed(0));
  late final _accessCode = TextEditingController(text: widget.initial?.accessCode);
  late EventVisibility _visibility = widget.initial?.visibility ?? EventVisibility.public;
  late DateTime? _date = widget.initial?.date;
  late TimeOfDay? _start = Fmt.parseTime(widget.initial?.startTime);
  late TimeOfDay? _end = Fmt.parseTime(widget.initial?.endTime);
  late String? _coverUrl = widget.initial?.coverImage;
  String? _localCover;
  bool _uploading = false;
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void dispose() {
    for (final c in [_name, _description, _venue, _guests, _budget, _accessCode]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickCover() async {
    final path = await pickImagePath();
    if (path == null) return;
    setState(() {
      _localCover = path;
      _uploading = true;
    });
    try {
      final url = await ref.read(eventRepositoryProvider).uploadCover(path);
      if (mounted) setState(() => _coverUrl = url);
    } catch (e) {
      if (!mounted) return;
      setState(() => _localCover = null);
      showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 14)),
      firstDate: _isEdit ? DateTime(now.year - 1) : now,
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (start ? _start : _end) ?? TimeOfDay(hour: start ? 18 : 22, minute: 0),
    );
    if (picked != null) setState(() => start ? _start = picked : _end = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null || _start == null) {
      showSnack(context, 'Please choose a date and start time.', error: true);
      return;
    }
    if (_uploading) {
      showSnack(context, 'Hang on, your cover photo is still uploading.', error: true);
      return;
    }
    setState(() => _saving = true);
    final draft = EventDraft(
      name: _name.text.trim(),
      description: _description.text.trim().isEmpty ? null : _description.text.trim(),
      visibility: _visibility,
      accessCode: _visibility == EventVisibility.private ? _accessCode.text.trim().toUpperCase() : null,
      date: _date!,
      startTime: '${Fmt.apiTime(_start!)}:00',
      endTime: _end == null ? null : '${Fmt.apiTime(_end!)}:00',
      venue: _venue.text.trim().isEmpty ? null : _venue.text.trim(),
      expectedAttendees: int.tryParse(_guests.text.trim()),
      budget: double.tryParse(_budget.text.trim()),
      coverImage: _coverUrl,
    );
    try {
      final repo = ref.read(eventRepositoryProvider);
      final saved = _isEdit ? await repo.update(widget.initial!.id, draft) : await repo.create(draft);
      invalidateEvents(ref, eventId: saved.id);
      if (!mounted) return;
      showSnack(context, _isEdit ? 'Event updated' : 'Event created 🎉');
      _isEdit ? context.pop() : context.pushReplacement(Routes.event(saved.id));
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit event' : 'New event')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            _CoverPicker(
              localPath: _localCover,
              url: _coverUrl,
              uploading: _uploading,
              onTap: _uploading ? null : _pickCover,
            ),
            const SizedBox(height: 24),
            const _Label('Event name'),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              validator: (v) => Validators.required(v, 'Event name'),
              decoration: const InputDecoration(hintText: "e.g. Amara's 30th Birthday"),
            ),
            const SizedBox(height: 18),
            const _Label('Description'),
            TextFormField(
              controller: _description,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Tell guests what to expect'),
            ),
            const SizedBox(height: 18),
            const _Label('Date & time'),
            _PickerField(icon: Icons.calendar_month_rounded, label: _date == null ? 'Choose a date' : Fmt.date(_date), onTap: _pickDate),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PickerField(
                    icon: Icons.schedule_rounded,
                    label: _start == null ? 'Starts' : Fmt.time(Fmt.apiTime(_start!)),
                    onTap: () => _pickTime(start: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerField(
                    icon: Icons.schedule_outlined,
                    label: _end == null ? 'Ends (optional)' : Fmt.time(Fmt.apiTime(_end!)),
                    onTap: () => _pickTime(start: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _Label('Venue'),
            TextFormField(
              controller: _venue,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Address or venue name', prefixIcon: Icon(Icons.place_outlined)),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label('Guests'),
                      TextFormField(
                        controller: _guests,
                        keyboardType: TextInputType.number,
                        validator: Validators.optionalPositiveInt,
                        decoration: const InputDecoration(hintText: '120', prefixIcon: Icon(Icons.groups_outlined)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label('Budget'),
                      TextFormField(
                        controller: _budget,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          hintText: '5,000',
                          prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _Label('Who can join?'),
            SegmentedButton<EventVisibility>(
              segments: const [
                ButtonSegment(value: EventVisibility.public, icon: Icon(Icons.public_rounded), label: Text('Public')),
                ButtonSegment(value: EventVisibility.private, icon: Icon(Icons.lock_rounded), label: Text('Private')),
              ],
              selected: {_visibility},
              onSelectionChanged: (s) => setState(() => _visibility = s.first),
            ),
            const SizedBox(height: 8),
            Text(
              _visibility == EventVisibility.public
                  ? 'Anyone on Invyte can discover and join.'
                  : 'Only guests with your access code can join.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (_visibility == EventVisibility.private) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _accessCode,
                textCapitalization: TextCapitalization.characters,
                validator: (v) {
                  if (_visibility != EventVisibility.private) return null;
                  // A code saved before the format rule stays valid until it's changed.
                  if (v?.trim().toUpperCase() == widget.initial?.accessCode) return null;
                  return Validators.accessCode(v);
                },
                decoration: const InputDecoration(hintText: 'Access code, e.g. LOVE2026', prefixIcon: Icon(Icons.key_rounded)),
              ),
            ],
            const SizedBox(height: 32),
            PrimaryButton(label: _isEdit ? 'Save changes' : 'Create event', loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );
}

class _PickerField extends StatelessWidget {
  const _PickerField({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(prefixIcon: Icon(icon)),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _CoverPicker extends StatelessWidget {
  const _CoverPicker({required this.localPath, required this.url, required this.uploading, required this.onTap});

  final String? localPath;
  final String? url;
  final bool uploading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = localPath != null || url != null;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Material(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (localPath != null)
                Image.file(File(localPath!), fit: BoxFit.cover)
              else if (url != null)
                AppImage(url),
              if (!hasImage)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_photo_alternate_rounded, size: 40, color: AppColors.primary),
                    const SizedBox(height: 8),
                    Text('Add a cover photo', style: theme.textTheme.titleSmall),
                    Text('Events with photos get 3× more guests',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              if (uploading)
                const ColoredBox(
                  color: Colors.black38,
                  child: Center(child: CircularProgressIndicator(color: Colors.white)),
                )
              else if (hasImage)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: FilledButton.tonalIcon(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Change'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
