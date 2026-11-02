class Post {
  const Post({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.content,
    required this.authorName,
    this.mediaUrls = const [],
    this.mediaType = 'image',
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.isPinned = false,
    this.isLiked = false,
    this.createdAt,
    this.authorAvatar,
  });

  final int id;
  final int eventId;
  final int userId;
  final String content;
  final List<String> mediaUrls;
  final String mediaType;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final bool isPinned;
  final bool isLiked;
  final DateTime? createdAt;
  final String authorName;
  final String? authorAvatar;

  Post copyWith({bool? isLiked, int? likeCount, int? commentCount}) => Post(
        id: id,
        eventId: eventId,
        userId: userId,
        content: content,
        authorName: authorName,
        mediaUrls: mediaUrls,
        mediaType: mediaType,
        likeCount: likeCount ?? this.likeCount,
        commentCount: commentCount ?? this.commentCount,
        shareCount: shareCount,
        isPinned: isPinned,
        isLiked: isLiked ?? this.isLiked,
        createdAt: createdAt,
        authorAvatar: authorAvatar,
      );
}

class Comment {
  const Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.authorName,
    this.parentId,
    this.createdAt,
    this.authorAvatar,
  });

  final int id;
  final int postId;
  final int userId;
  final String content;
  final int? parentId;
  final DateTime? createdAt;
  final String authorName;
  final String? authorAvatar;
}

/// A message in an event's group chat.
class EventChatMessage {
  const EventChatMessage({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.message,
    required this.authorName,
    this.type = 'text',
    this.mediaUrl,
    this.createdAt,
    this.authorAvatar,
  });

  final int id;
  final int eventId;
  final int userId;
  final String message;
  final String type;
  final String? mediaUrl;
  final DateTime? createdAt;
  final String authorName;
  final String? authorAvatar;
}
