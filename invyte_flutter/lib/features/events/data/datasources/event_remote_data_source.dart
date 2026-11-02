import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json.dart';

class EventRemoteDataSource {
  const EventRemoteDataSource(this._api);

  final ApiClient _api;

  Future<Object?> list({String? search, String? eventType, int page = 1, int limit = 20}) =>
      _api.get('api/events', query: {
        'search': search,
        'event_type': eventType,
        'page': page,
        'limit': limit,
      });

  Future<Object?> myEvents({int page = 1, int limit = 50}) =>
      _api.get('api/events/my-events', query: {'page': page, 'limit': limit});

  Future<Json> get(int id) async => asJson(await _api.get('api/events/$id'));

  Future<Json> create(Json body) async => asJson(await _api.post('api/events', body: body));

  Future<Json> update(int id, Json body) async => asJson(await _api.put('api/events/$id', body: body));

  Future<void> delete(int id) => _api.delete('api/events/$id');

  Future<Object?> join(int id, String accessCode) =>
      _api.post('api/events/$id/join', body: {'access_code': accessCode});

  Future<Json> joinByCode(String accessCode) async =>
      asJson(await _api.post('api/events/join', body: {'access_code': accessCode}));

  Future<Json> toggleLike(int id) async => asJson(await _api.post('api/events/$id/like'));

  Future<Json> uploadCover(String filePath) async =>
      asJson(await _api.upload('api/events/upload-cover', fileField: 'cover_image', filePath: filePath));
}
