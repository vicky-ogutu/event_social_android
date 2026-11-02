import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json.dart';

class LivestreamRemoteDataSource {
  const LivestreamRemoteDataSource(this._api);

  final ApiClient _api;

  Future<Json> joinInfo(int id) async => asJson(await _api.post('api/livestream/$id/token'));

  Future<Object?> forEvent(int eventId) => _api.get('api/livestream/event/$eventId');

  Future<Json> create(int eventId, double price) async =>
      asJson(await _api.post('api/livestream', body: {'event_id': eventId, 'pay_per_view_price': price}));

  Future<void> start(int id) => _api.post('api/livestream/$id/start');

  Future<void> end(int id) => _api.post('api/livestream/$id/end');

  Future<Json> purchase(int id) async => asJson(await _api.post('api/livestream/$id/purchase'));

  Future<void> confirmPurchase(int id, String paymentIntentId) => _api.post(
        'api/livestream/confirm-purchase',
        body: {'livestream_id': id, 'payment_intent_id': paymentIntentId},
      );
}
