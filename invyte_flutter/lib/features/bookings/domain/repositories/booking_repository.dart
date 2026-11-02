import '../entities/booking.dart';

abstract interface class BookingRepository {
  Future<Booking> create(BookingDraft draft);

  /// Bookings the signed-in customer has made.
  Future<List<Booking>> myBookings();

  /// Booking requests received by the signed-in vendor.
  Future<List<Booking>> vendorBookings();

  Future<Booking> getBooking(int id);

  /// Vendor accepts a pending request.
  Future<void> accept(int id);

  /// Vendor declines a pending request.
  Future<void> decline(int id);

  Future<void> complete(int id);

  Future<PaymentIntent> createPaymentIntent(int bookingId);

  /// Tells the server a payment sheet succeeded so it can verify the
  /// PaymentIntent with Stripe and mark the booking paid.
  Future<Booking> confirmPayment(String paymentIntentId);
}
