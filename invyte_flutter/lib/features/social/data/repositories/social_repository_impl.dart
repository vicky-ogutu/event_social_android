import '../../../../core/error/failure.dart';
import '../../../../core/realtime/realtime_service.dart';
import '../../../../core/utils/json.dart';
import '../../domain/entities/social.dart';
import '../../domain/repositories/social_repository.dart';
import '../datasources/social_remote_data_source.dart';
import '../models/social_mapper.dart';

class SocialRepositoryImpl implements SocialRepository {
  const SocialRepositoryImpl(this._remote, this._realtime);

  final SocialRemoteDataSource _remote;
  final RealtimeService _realtime;

  @override
  Future<List<Post>> feed({int? eventId}) =>
      guard(() async => asList(_unwrap(await _remote.feed(eventId: eventId)), SocialMapper.post));

  @override
  Future<Post> createPost({required int eventId, required String content, List<String> mediaUrls = const []}) =>
      guard(() async => SocialMapper.post(await _remote.createPost({
            'event_id': eventId,
            'content': content,
            'media_urls': mediaUrls,
            'media_type': 'image',
          })));

  @override
  Future<String> uploadMedia(String filePath) => guard(() async {
        final url = asStringOrNull((await _remote.uploadMedia(filePath))['url']);
        if (url == null) throw const Failure('Upload failed. Please try another photo.');
        return url;
      });

  @override
  Future<void> toggleLike(int postId) => guard(() => _remote.toggleLike(postId));

  @override
  Future<List<Comment>> comments(int postId) =>
      guard(() async => asList(await _remote.comments(postId), SocialMapper.comment));

  @override
  Future<Comment> addComment(int postId, String content) =>
      guard(() async => SocialMapper.comment(await _remote.addComment(postId, content)));

  @override
  Future<List<EventChatMessage>> eventChat(int eventId) => guard(() async {
        final messages = asList(_unwrap(await _remote.eventChat(eventId)), SocialMapper.chat);
        // Oldest first for display.
        messages.sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
        return messages;
      });

  @override
  Future<EventChatMessage> sendEventChat(int eventId, String message) =>
      guard(() async => SocialMapper.chat(await _remote.sendEventChat(eventId, message)));

  @override
  Stream<EventChatMessage> watchEventChat(int eventId) async* {
    _realtime.joinEvent(eventId);
    try {
      yield* _realtime.eventMessages.map(SocialMapper.chat).where((m) => m.eventId == eventId);
    } finally {
      _realtime.leaveEvent(eventId);
    }
  }

  static Object? _unwrap(Object? data) => data is Map ? data['data'] : data;
}
