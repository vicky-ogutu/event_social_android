import '../../../../core/error/failure.dart';
import '../../../../core/utils/json.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_remote_data_source.dart';
import '../models/booking_mapper.dart';

class BookingRepositoryImpl implements BookingRepository {
  const BookingRepositoryImpl(this._remote);

  final BookingRemoteDataSource _remote;

  @override
  Future<Booking> create(BookingDraft draft) =>
      guard(() async => BookingMapper.fromJson(await _remote.create(BookingMapper.toJson(draft))));

  @override
  Future<List<Booking>> myBookings() => guard(() async => _list(await _remote.myBookings()));

  @override
  Future<List<Booking>> vendorBookings() => guard(() async => _list(await _remote.vendorBookings()));

  @override
  Future<Booking> getBooking(int id) => guard(() async => BookingMapper.fromJson(await _remote.get(id)));

  @override
  Future<void> accept(int id) => guard(() => _remote.confirm(id));

  @override
  Future<void> decline(int id) => guard(() => _remote.reject(id));

  @override
  Future<void> complete(int id) => guard(() => _remote.complete(id));

  @override
  Future<PaymentIntent> createPaymentIntent(int bookingId) =>
      guard(() async => BookingMapper.paymentIntent(await _remote.createPaymentIntent(bookingId)));

  @override
  Future<Booking> confirmPayment(String paymentIntentId) =>
      guard(() async => BookingMapper.fromJson(await _remote.confirmPayment(paymentIntentId)));

  /// Accepts a bare list or a paginated `{ data: [...] }` envelope.
  static List<Booking> _list(Object? data) =>
      asList(data is Map ? data['data'] ?? data['bookings'] : data, BookingMapper.fromJson);
}
