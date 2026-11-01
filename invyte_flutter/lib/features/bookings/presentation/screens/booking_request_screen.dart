import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../../vendors/domain/entities/vendor.dart';
import '../../../vendors/presentation/providers/vendor_providers.dart';
import '../../domain/entities/booking.dart';
import '../providers/booking_providers.dart';
import '../widgets/booking_widgets.dart';

class BookingRequestScreen extends ConsumerWidget {
  const BookingRequestScreen({super.key, required this.vendorId, required this.serviceId});

  final int vendorId;
  final int serviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendor = ref.watch(vendorDetailProvider(vendorId));
    // The detail payload may omit services; fall back to the dedicated endpoint.
    final services = ref.watch(vendorServicesProvider(vendorId)).value ?? const <VendorService>[];
    final events = ref.watch(upcomingMyEventsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Request booking')),
      body: AsyncValueView(
        value: vendor,
        onRetry: () => ref.invalidate(vendorDetailProvider(vendorId)),
        data: (Vendor v) {
          final service = [...v.services, ...services].where((s) => s.id == serviceId).firstOrNull;
          if (service == null) {
            return const EmptyState(icon: Icons.search_off_rounded, title: 'Service not available');
          }
          return AsyncValueView(
            value: events,
            onRetry: () => ref.invalidate(myEventsProvider),
            data: (List<Event> list) => list.isEmpty
                ? EmptyState(
                    icon: Icons.event_rounded,
                    title: 'Create an event first',
                    message: 'Bookings are attached to one of your events so vendors know the details.',
                    actionLabel: 'Create event',
                    onAction: () => context.push(Routes.newEvent),
                  )
                : _BookingForm(vendor: v, service: service, events: list),
          );
        },
      ),
    );
  }
}

class _BookingForm extends ConsumerStatefulWidget {
  const _BookingForm({required this.vendor, required this.service, required this.events});

  final Vendor vendor;
  final VendorService service;
  final List<Event> events;

  @override
  ConsumerState<_BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends ConsumerState<_BookingForm> {
  late Event _event = widget.events.first;
  late DateTime _date = _event.date ?? DateTime.now().add(const Duration(days: 7));
  late TimeOfDay _time = Fmt.parseTime(_event.startTime) ?? const TimeOfDay(hour: 12, minute: 0);
  late int _quantity = _defaultQuantity(_event);
  final _notes = TextEditingController();
  bool _submitting = false;

  bool get _perGuest => widget.service.priceUnit == 'guest' || widget.service.priceUnit == 'person';

  int _defaultQuantity(Event e) =>
      widget.service.priceUnit == 'guest' ? (e.expectedAttendees ?? 50) : 1;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _selectEvent(Event e) => setState(() {
        _event = e;
        _date = e.date ?? _date;
        _time = Fmt.parseTime(e.startTime) ?? _time;
        _quantity = _defaultQuantity(e);
      });

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(now) ? now : _date,
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final booking = await ref.read(bookingRepositoryProvider).create(BookingDraft(
            eventId: _event.id,
            serviceId: widget.service.id,
            serviceDate: _date,
            serviceTime: '${Fmt.apiTime(_time)}:00',
            quantity: _quantity,
            specialRequests: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          ));
      invalidateBookings(ref);
      if (!mounted) return;
      showSnack(context, 'Request sent to ${widget.vendor.businessName}');
      context.pushReplacement(Routes.checkout(booking.id));
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtotal = widget.service.basePrice * _quantity;
    final fee = subtotal * AppConfig.estimatedServiceFeeRate;
    final tax = subtotal * AppConfig.estimatedTaxRate;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      AppImage(
                        widget.vendor.heroImage,
                        width: 64,
                        height: 64,
                        borderRadius: BorderRadius.circular(16),
                        placeholderSeed: widget.vendor.businessName,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.service.name, style: theme.textTheme.titleMedium),
                            Text(widget.vendor.businessName,
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            Text('${Fmt.money(widget.service.basePrice)} ${widget.service.unitLabel}',
                                style: theme.textTheme.titleSmall?.copyWith(color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('For which event?', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: _event.id,
                isExpanded: true,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.celebration_rounded)),
                items: [
                  for (final e in widget.events)
                    DropdownMenuItem(value: e.id, child: Text(e.name, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (id) => _selectEvent(widget.events.firstWhere((e) => e.id == id)),
              ),
              const SizedBox(height: 20),
              Text('When?', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _PickerTile(icon: Icons.calendar_month_rounded, label: Fmt.date(_date), onTap: _pickDate),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PickerTile(
                      icon: Icons.schedule_rounded,
                      label: Fmt.time(Fmt.apiTime(_time)),
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_perGuest ? 'Guests' : 'Quantity', style: theme.textTheme.titleMedium),
                        Text(
                          widget.service.priceUnit == null ? 'Units' : 'Priced per ${widget.service.priceUnit}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  _Stepper(
                    value: _quantity,
                    step: _perGuest ? 10 : 1,
                    onChanged: (v) => setState(() => _quantity = v),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Special requests', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              TextField(
                controller: _notes,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Dietary needs, timings, themes… (optional)'),
              ),
              const SizedBox(height: 20),
              Panel(
                title: 'Price estimate',
                child: PriceBreakdown(
                  subtotal: subtotal,
                  subtotalLabel: '${Fmt.money(widget.service.basePrice)} × $_quantity',
                  serviceFee: fee,
                  tax: tax,
                  total: subtotal + fee + tax,
                  estimate: true,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.shield_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your payment is held securely and only released once the service is delivered.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: PrimaryButton(
              label: 'Request & continue to payment',
              loading: _submitting,
              onPressed: _submit,
            ),
          ),
        ),
      ],
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.onChanged, this.step = 1});

  final int value;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: value > 1 ? () => onChanged((value - step).clamp(1, 100000)) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          SizedBox(
            width: 44,
            child: Text('$value', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          ),
          IconButton(onPressed: () => onChanged(value + step), icon: const Icon(Icons.add_rounded)),
        ],
      ),
    );
  }
}
