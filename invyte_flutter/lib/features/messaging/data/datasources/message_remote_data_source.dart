import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json.dart';

class MessageRemoteDataSource {
  const MessageRemoteDataSource(this._api);

  final ApiClient _api;

  Future<Object?> conversations() => _api.get('api/messages/conversations');

  Future<Object?> thread(int userId) => _api.get('api/messages/$userId', query: {'limit': 100, 'offset': 0});

  Future<Json> send(int receiverId, String message) async =>
      asJson(await _api.post('api/messages', body: {'receiver_id': receiverId, 'message': message}));
}
