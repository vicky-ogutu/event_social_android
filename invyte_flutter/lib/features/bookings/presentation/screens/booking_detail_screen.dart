import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../vendors/presentation/providers/vendor_providers.dart';
import '../../domain/entities/booking.dart';
import '../providers/booking_providers.dart';
import '../widgets/booking_actions.dart';
import '../widgets/booking_widgets.dart';

class BookingDetailScreen extends ConsumerWidget {
  const BookingDetailScreen({super.key, required this.bookingId});

  final int bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(bookingDetailProvider(bookingId));
    final isVendor = ref.watch(currentUserProvider)?.isVendor ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('Booking details')),
      body: AsyncValueView(
        value: booking,
        onRetry: () => ref.invalidate(bookingDetailProvider(bookingId)),
        data: (Booking b) => RefreshIndicator(
          onRefresh: () => ref.refresh(bookingDetailProvider(bookingId).future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              _Header(booking: b, vendorView: isVendor),
              const SizedBox(height: 16),
              Panel(title: 'Progress', child: _Timeline(booking: b)),
              const SizedBox(height: 16),
              Panel(
                title: 'Details',
                child: Column(
                  children: [
                    InfoRow(icon: Icons.design_services_rounded, title: b.serviceName ?? 'Service', subtitle: 'Quantity: ${b.quantity}'),
                    InfoRow(
                      icon: isVendor ? Icons.person_rounded : Icons.storefront_rounded,
                      title: isVendor ? (b.consumerName ?? 'Customer') : (b.vendorName ?? 'Vendor'),
                      subtitle: isVendor ? 'Customer' : 'Vendor',
                    ),
                    InfoRow(
                      icon: Icons.celebration_rounded,
                      title: b.eventName ?? 'Event',
                      subtitle: 'Event',
                      trailing: IconButton(
                        onPressed: () => context.push(Routes.event(b.eventId)),
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ),
                    InfoRow(
                      icon: Icons.calendar_month_rounded,
                      title: Fmt.date(b.serviceDate),
                      subtitle: 'Starts at ${Fmt.time(b.serviceTime)}',
                    ),
                  ],
                ),
              ),
              if (b.specialRequests != null) ...[
                const SizedBox(height: 16),
                Panel(title: 'Special requests', child: Text(b.specialRequests!)),
              ],
              const SizedBox(height: 16),
              Panel(
                title: 'Payment',
                child: Column(
                  children: [
                    PriceBreakdown(
                      subtotal: b.agreedPrice,
                      serviceFee: b.serviceFee,
                      tax: b.taxAmount,
                      total: b.totalAmount,
                      paid: b.amountPaid,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          b.isPaid ? Icons.verified_user_rounded : Icons.schedule_rounded,
                          size: 18,
                          color: b.isPaid ? AppColors.success : AppColors.warning,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          b.isPaid ? 'Paid securely via Invyte' : 'Awaiting payment',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: b.isPaid ? AppColors.success : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (isVendor) VendorBookingActions(booking: b) else _CustomerActions(booking: b),
              const SizedBox(height: 12),
              _MessageButton(booking: b, vendorView: isVendor),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.booking, required this.vendorView});

  final Booking booking;
  final bool vendorView;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: booking.reference));
                      if (context.mounted) showSnack(context, 'Reference copied');
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(booking.reference,
                            style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(width: 4),
                        Icon(Icons.copy_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(Fmt.money(vendorView ? booking.agreedPrice : booking.totalAmount),
                      style: theme.textTheme.headlineMedium),
                ],
              ),
            ),
            BookingStatusChip(status: booking.status, vendorView: vendorView),
          ],
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final status = booking.status;
    final declined = status.isClosed;
    final steps = [
      ('Requested', Fmt.date(booking.bookingDate), true),
      (
        declined ? status.label : 'Confirmed by vendor',
        declined ? 'This booking was ${status.label.toLowerCase()}' : null,
        status == BookingStatus.confirmed || status == BookingStatus.completed || declined,
      ),
      ('Paid', null, booking.isPaid),
      ('Completed', null, status == BookingStatus.completed),
    ];
    return Column(
      children: [
        for (final (i, (label, sub, done)) in steps.indexed)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? (declined && i == 1 ? AppColors.danger : AppColors.success)
                            : Theme.of(context).colorScheme.surfaceContainerHigh,
                      ),
                      child: done
                          ? Icon(declined && i == 1 ? Icons.close_rounded : Icons.check_rounded,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                    if (i < steps.length - 1)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: done ? null : Theme.of(context).colorScheme.onSurfaceVariant,
                                )),
                        if (sub != null)
                          Text(sub,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CustomerActions extends ConsumerStatefulWidget {
  const _CustomerActions({required this.booking});

  final Booking booking;

  @override
  ConsumerState<_CustomerActions> createState() => _CustomerActionsState();
}

class _CustomerActionsState extends ConsumerState<_CustomerActions> {
  bool _busy = false;

  Future<void> _complete() async {
    final ok = await confirmAction(
      context,
      title: 'Mark as completed?',
      message: 'Confirm that ${widget.booking.vendorName ?? 'the vendor'} delivered this service. '
          'This releases payment to the vendor.',
      confirmLabel: 'Confirm',
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      await ref.read(bookingRepositoryProvider).complete(widget.booking.id);
      invalidateBookings(ref, bookingId: widget.booking.id);
      if (mounted) showSnack(context, 'Thanks! Booking completed.');
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    if (!b.isPaid && !b.status.isClosed) {
      return PrimaryButton(
        label: 'Pay ${Fmt.money(b.balanceDue)}',
        icon: Icons.lock_rounded,
        onPressed: () => context.push(Routes.checkout(b.id)),
      );
    }
    if (b.status == BookingStatus.confirmed) {
      return OutlinedButton.icon(
        onPressed: _busy ? null : _complete,
        icon: const Icon(Icons.task_alt_rounded),
        label: const Text('Mark service as completed'),
      );
    }
    return const SizedBox.shrink();
  }
}

class _MessageButton extends ConsumerWidget {
  const _MessageButton({required this.booking, required this.vendorView});

  final Booking booking;
  final bool vendorView;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (vendorView) {
      return TextButton.icon(
        onPressed: () => context.push(Routes.chat(booking.consumerId, name: booking.consumerName ?? 'Customer')),
        icon: const Icon(Icons.chat_bubble_outline_rounded),
        label: const Text('Message customer'),
      );
    }
    // Messages are addressed to the vendor's user account, not the vendor id.
    final vendor = ref.watch(vendorDetailProvider(booking.vendorId)).value;
    return TextButton.icon(
      onPressed: vendor == null
          ? null
          : () => context.push(Routes.chat(vendor.userId, name: vendor.businessName, avatar: vendor.profilePicture)),
      icon: const Icon(Icons.chat_bubble_outline_rounded),
      label: Text('Message ${booking.vendorName ?? 'vendor'}'),
    );
  }
}
