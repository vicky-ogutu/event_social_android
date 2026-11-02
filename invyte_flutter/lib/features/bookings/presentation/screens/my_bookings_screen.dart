import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/booking.dart';
import '../providers/booking_providers.dart';
import '../widgets/booking_widgets.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(myBookingsProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My bookings'),
          bottom: const TabBar(tabs: [Tab(text: 'Active'), Tab(text: 'Past')]),
        ),
        body: AsyncValueView(
          value: bookings,
          onRetry: () => ref.invalidate(myBookingsProvider),
          data: (List<Booking> all) {
            final active = all
                .where((b) => b.status == BookingStatus.pending || b.status == BookingStatus.confirmed)
                .toList();
            final past = all.where((b) => !active.contains(b)).toList();
            return TabBarView(
              children: [
                _List(bookings: active, empty: 'No active bookings', showBrowse: true),
                _List(bookings: past, empty: 'No past bookings yet'),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _List extends ConsumerWidget {
  const _List({required this.bookings, required this.empty, this.showBrowse = false});

  final List<Booking> bookings;
  final String empty;
  final bool showBrowse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(myBookingsProvider.future),
      child: bookings.isEmpty
          ? ListView(children: [
              EmptyState(
                icon: Icons.receipt_long_rounded,
                title: empty,
                message: showBrowse ? 'Find the perfect vendor for your next event.' : null,
                actionLabel: showBrowse ? 'Browse vendors' : null,
                onAction: showBrowse ? () => context.go(Routes.discover) : null,
              ),
            ])
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: bookings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => BookingCard(booking: bookings[i]),
            ),
    );
  }
}
