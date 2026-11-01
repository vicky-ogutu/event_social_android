import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json.dart';

class SocialRemoteDataSource {
  const SocialRemoteDataSource(this._api);

  final ApiClient _api;

  Future<Object?> feed({int? eventId}) =>
      _api.get('api/social/feed', query: {'event_id': eventId, 'page': 1, 'limit': 30});

  Future<Json> createPost(Json body) async => asJson(await _api.post('api/social/posts', body: body));

  Future<Json> uploadMedia(String filePath) async =>
      asJson(await _api.upload('api/social/upload', fileField: 'media', filePath: filePath));

  Future<void> toggleLike(int postId) => _api.post('api/social/posts/$postId/like');

  Future<Object?> comments(int postId) => _api.get('api/social/posts/$postId/comments');

  Future<Json> addComment(int postId, String content) async => asJson(await _api.post(
        'api/social/posts/$postId/comment',
        body: {'post_id': postId, 'content': content},
      ));

  Future<Object?> eventChat(int eventId) =>
      _api.get('api/social/events/$eventId/chat', query: {'page': 1, 'limit': 50});

  Future<Json> sendEventChat(int eventId, String message) async => asJson(await _api.post(
        'api/social/chat',
        body: {'event_id': eventId, 'message': message, 'message_type': 'text'},
      ));
}
