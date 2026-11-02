import '../../../../core/utils/json.dart';
import '../../domain/entities/social.dart';

abstract final class SocialMapper {
  static Post post(Json json) => Post(
        id: asInt(json['id']),
        eventId: asInt(json['event_id']),
        userId: asInt(json['user_id']),
        content: asString(json['content']),
        mediaUrls: asStringList(json['media_urls']),
        mediaType: asString(json['media_type'], 'image'),
        likeCount: asInt(json['like_count']),
        commentCount: asInt(json['comment_count']),
        shareCount: asInt(json['share_count']),
        isPinned: asBool(json['is_pinned']),
        isLiked: asBool(json['is_liked']),
        createdAt: asDateTime(json['created_at']),
        authorName: asString(json['full_name'], 'Invyte member'),
        authorAvatar: asStringOrNull(json['profile_picture']),
      );

  static Comment comment(Json json) => Comment(
        id: asInt(json['id']),
        postId: asInt(json['post_id']),
        userId: asInt(json['user_id']),
        content: asString(json['content']),
        parentId: asIntOrNull(json['parent_comment_id']),
        createdAt: asDateTime(json['created_at']),
        authorName: asString(json['full_name'], 'Invyte member'),
        authorAvatar: asStringOrNull(json['profile_picture']),
      );

  static EventChatMessage chat(Json json) => EventChatMessage(
        id: asInt(json['id']),
        eventId: asInt(json['event_id'] ?? json['eventId']),
        userId: asInt(json['user_id'] ?? json['userId']),
        message: asString(json['message']),
        type: asString(json['message_type'] ?? json['messageType'], 'text'),
        mediaUrl: asStringOrNull(json['media_url'] ?? json['mediaUrl']),
        createdAt: asDateTime(json['created_at']) ?? DateTime.now(),
        authorName: asString(json['full_name'], 'Guest'),
        authorAvatar: asStringOrNull(json['profile_picture']),
      );
}
