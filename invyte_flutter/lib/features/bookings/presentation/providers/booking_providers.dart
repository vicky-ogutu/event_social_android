import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../data/datasources/booking_remote_data_source.dart';
import '../../data/repositories/booking_repository_impl.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  ref.watch(sessionScopeProvider);
  return BookingRepositoryImpl(BookingRemoteDataSource(ref.watch(apiClientProvider)));
});

final myBookingsProvider = FutureProvider<List<Booking>>(
  (ref) => ref.watch(bookingRepositoryProvider).myBookings(),
);

final vendorBookingsProvider = FutureProvider<List<Booking>>(
  (ref) => ref.watch(bookingRepositoryProvider).vendorBookings(),
);

final bookingDetailProvider = FutureProvider.autoDispose.family<Booking, int>(
  (ref, id) => ref.watch(bookingRepositoryProvider).getBooking(id),
);

/// Aggregates shown on the vendor dashboard.
class VendorStats {
  const VendorStats({
    required this.revenue,
    required this.pending,
    required this.upcoming,
    required this.completed,
    required this.monthlyRevenue,
  });

  final double revenue;
  final List<Booking> pending;
  final List<Booking> upcoming;
  final int completed;

  /// Last six months, oldest first: (month start, revenue).
  final List<(DateTime, double)> monthlyRevenue;

  factory VendorStats.from(List<Booking> bookings) {
    final now = DateTime.now();
    final months = [for (var i = 5; i >= 0; i--) DateTime(now.year, now.month - i)];
    final revenueByMonth = {for (final m in months) m: 0.0};
    var revenue = 0.0;
    for (final b in bookings.where((b) => b.status == BookingStatus.completed)) {
      revenue += b.agreedPrice;
      final date = b.serviceDate;
      if (date == null) continue;
      final key = DateTime(date.year, date.month);
      if (revenueByMonth.containsKey(key)) revenueByMonth[key] = revenueByMonth[key]! + b.agreedPrice;
    }
    return VendorStats(
      revenue: revenue,
      pending: bookings.where((b) => b.status == BookingStatus.pending).toList(),
      upcoming: bookings.where((b) => b.status == BookingStatus.confirmed).toList()
        ..sort((a, b) => (a.serviceDate ?? now).compareTo(b.serviceDate ?? now)),
      completed: bookings.where((b) => b.status == BookingStatus.completed).length,
      monthlyRevenue: [for (final m in months) (m, revenueByMonth[m]!)],
    );
  }
}

final vendorStatsProvider = Provider<AsyncValue<VendorStats>>(
  (ref) => ref.watch(vendorBookingsProvider).whenData(VendorStats.from),
);

void invalidateBookings(WidgetRef ref, {int? bookingId}) {
  ref.invalidate(myBookingsProvider);
  ref.invalidate(vendorBookingsProvider);
  if (bookingId != null) ref.invalidate(bookingDetailProvider(bookingId));
}
