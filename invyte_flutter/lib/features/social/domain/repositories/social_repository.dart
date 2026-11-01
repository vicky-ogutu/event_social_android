import '../entities/social.dart';

abstract interface class SocialRepository {
  Future<List<Post>> feed({int? eventId});

  Future<Post> createPost({required int eventId, required String content, List<String> mediaUrls = const []});

  /// Uploads a photo for a post and returns its public URL.
  Future<String> uploadMedia(String filePath);

  Future<void> toggleLike(int postId);

  Future<List<Comment>> comments(int postId);

  Future<Comment> addComment(int postId, String content);

  Future<List<EventChatMessage>> eventChat(int eventId);

  Future<EventChatMessage> sendEventChat(int eventId, String message);

  /// Live messages pushed for [eventId].
  Stream<EventChatMessage> watchEventChat(int eventId);
}
