import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/common.dart';
import '../../domain/entities/booking.dart';

Color bookingStatusColor(BookingStatus status) => switch (status) {
      BookingStatus.pending => AppColors.warning,
      BookingStatus.confirmed => AppColors.info,
      BookingStatus.completed => AppColors.success,
      BookingStatus.rejected || BookingStatus.cancelled => AppColors.danger,
      BookingStatus.unknown => AppColors.inkMuted,
    };

class BookingStatusChip extends StatelessWidget {
  const BookingStatusChip({super.key, required this.status, this.vendorView = false});

  final BookingStatus status;
  final bool vendorView;

  @override
  Widget build(BuildContext context) {
    final label = vendorView && status == BookingStatus.pending ? 'New request' : status.label;
    return StatusChip(label: label, color: bookingStatusColor(status), dense: true);
  }
}

class BookingCard extends StatelessWidget {
  const BookingCard({super.key, required this.booking, this.vendorView = false, this.actions});

  final Booking booking;
  final bool vendorView;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final counterpart = vendorView ? (booking.consumerName ?? 'Customer') : (booking.vendorName ?? 'Vendor');
    return Card(
      child: InkWell(
        onTap: () => context.push(Routes.booking(booking.id)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _DateTile(date: booking.serviceDate),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(booking.serviceName ?? 'Service',
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(counterpart,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(color: muted)),
                        const SizedBox(height: 2),
                        Text(
                          '${booking.eventName ?? 'Event'} · ${Fmt.time(booking.serviceTime)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  BookingStatusChip(status: booking.status, vendorView: vendorView),
                  const SizedBox(width: 6),
                  if (!vendorView && !booking.isPaid && !booking.status.isClosed)
                    const StatusChip(label: 'Payment due', color: AppColors.primary, dense: true),
                  const Spacer(),
                  Text(
                    Fmt.money(vendorView ? booking.agreedPrice : booking.totalAmount),
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
              if (actions != null) ...[const SizedBox(height: 14), actions!],
            ],
          ),
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.date});

  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(Fmt.monthShort(date),
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.6)),
          Text(Fmt.day(date),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, height: 1.1)),
        ],
      ),
    );
  }
}

/// Itemised price summary.
class PriceBreakdown extends StatelessWidget {
  const PriceBreakdown({
    super.key,
    required this.subtotal,
    required this.serviceFee,
    this.tax = 0,
    required this.total,
    this.subtotalLabel = 'Service subtotal',
    this.estimate = false,
    this.paid,
  });

  final double subtotal;
  final double serviceFee;
  final double tax;
  final double total;
  final String subtotalLabel;
  final bool estimate;
  final double? paid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget row(String label, double value, {bool bold = false, Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Expanded(
                child: Text(label,
                    style: bold
                        ? theme.textTheme.titleMedium
                        : theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ),
              Text(Fmt.money(value),
                  style: (bold ? theme.textTheme.titleMedium : theme.textTheme.bodyMedium)?.copyWith(color: color)),
            ],
          ),
        );

    return Column(
      children: [
        row(subtotalLabel, subtotal),
        row('Invyte service fee', serviceFee),
        if (tax > 0) row('Taxes', tax),
        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
        row(estimate ? 'Estimated total' : 'Total', total, bold: true),
        if (paid != null && paid! > 0) row('Paid', -paid!, color: AppColors.success),
      ],
    );
  }
}
