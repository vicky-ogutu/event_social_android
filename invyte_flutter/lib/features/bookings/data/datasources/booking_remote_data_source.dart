import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json.dart';

class BookingRemoteDataSource {
  const BookingRemoteDataSource(this._api);

  final ApiClient _api;

  Future<Json> create(Json body) async => asJson(await _api.post('api/bookings', body: body));

  Future<Object?> myBookings() => _api.get('api/bookings/my-bookings', query: {'page': 1, 'limit': 50});

  Future<Object?> vendorBookings() => _api.get('api/bookings/vendor');

  Future<Json> get(int id) async => asJson(await _api.get('api/bookings/$id'));

  Future<void> confirm(int id) => _api.post('api/bookings/$id/confirm-service');

  Future<void> reject(int id) => _api.post('api/bookings/$id/reject');

  Future<void> complete(int id) => _api.post('api/bookings/$id/complete');

  Future<Json> createPaymentIntent(int bookingId) async =>
      asJson(await _api.post('api/payments/create-intent', body: {'booking_id': bookingId}));

  Future<Json> confirmPayment(String paymentIntentId) async =>
      asJson(await _api.post('api/payments/confirm', body: {'payment_intent_id': paymentIntentId}));
}
