import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/common.dart';
import '../../domain/entities/booking.dart';
import '../providers/booking_providers.dart';

/// Accept / decline / complete buttons for the vendor side of a booking.
class VendorBookingActions extends ConsumerStatefulWidget {
  const VendorBookingActions({super.key, required this.booking});

  final Booking booking;

  @override
  ConsumerState<VendorBookingActions> createState() => _VendorBookingActionsState();
}

class _VendorBookingActionsState extends ConsumerState<VendorBookingActions> {
  String? _busy;

  Future<void> _run(String action, Future<void> Function() call, String success) async {
    setState(() => _busy = action);
    try {
      await call();
      invalidateBookings(ref, bookingId: widget.booking.id);
      if (mounted) showSnack(context, success);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _decline() async {
    final ok = await confirmAction(
      context,
      title: 'Decline this request?',
      message: 'The customer will be notified and can book another vendor.',
      confirmLabel: 'Decline',
      destructive: true,
    );
    if (!ok) return;
    final repo = ref.read(bookingRepositoryProvider);
    await _run('decline', () => repo.decline(widget.booking.id), 'Request declined');
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(bookingRepositoryProvider);
    final id = widget.booking.id;
    return switch (widget.booking.status) {
      BookingStatus.pending => Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy != null ? null : _decline,
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                child: _busy == 'decline' ? const _Spinner() : const Text('Decline'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _busy != null ? null : () => _run('accept', () => repo.accept(id), 'Booking accepted 🎉'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                child: _busy == 'accept' ? const _Spinner(light: true) : const Text('Accept'),
              ),
            ),
          ],
        ),
      BookingStatus.confirmed => FilledButton.icon(
          onPressed: _busy != null
              ? null
              : () => _run('complete', () => repo.complete(id), 'Marked as completed'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46), backgroundColor: AppColors.success),
          icon: _busy == 'complete' ? const _Spinner(light: true) : const Icon(Icons.task_alt_rounded),
          label: const Text('Mark as completed'),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner({this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: light ? Colors.white : null),
      );
}
