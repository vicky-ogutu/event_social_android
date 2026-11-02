import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/booking.dart';
import '../providers/booking_providers.dart';
import '../widgets/booking_actions.dart';
import '../widgets/booking_widgets.dart';

class VendorBookingsScreen extends ConsumerWidget {
  const VendorBookingsScreen({super.key});

  static const _tabs = [
    ('Requests', [BookingStatus.pending]),
    ('Upcoming', [BookingStatus.confirmed]),
    ('Completed', [BookingStatus.completed]),
    ('Declined', [BookingStatus.rejected, BookingStatus.cancelled]),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(vendorBookingsProvider);
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bookings'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (final (label, statuses) in _tabs)
                Tab(
                  text: bookings.hasValue
                      ? '$label (${bookings.value!.where((b) => statuses.contains(b.status)).length})'
                      : label,
                ),
            ],
          ),
        ),
        body: AsyncValueView(
          value: bookings,
          onRetry: () => ref.invalidate(vendorBookingsProvider),
          data: (List<Booking> all) => TabBarView(
            children: [
              for (final (label, statuses) in _tabs)
                _BookingList(
                  bookings: all.where((b) => statuses.contains(b.status)).toList(),
                  emptyLabel: 'No ${label.toLowerCase()} bookings',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingList extends ConsumerWidget {
  const _BookingList({required this.bookings, required this.emptyLabel});

  final List<Booking> bookings;
  final String emptyLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(vendorBookingsProvider.future),
      child: bookings.isEmpty
          ? ListView(children: [EmptyState(icon: Icons.event_note_rounded, title: emptyLabel)])
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: bookings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => BookingCard(
                booking: bookings[i],
                vendorView: true,
                actions: VendorBookingActions(booking: bookings[i]),
              ),
            ),
    );
  }
}
