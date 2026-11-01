import '../../../../core/utils/json.dart';
import '../../domain/entities/message.dart';

abstract final class MessageMapper {
  static Conversation conversation(Json json) => Conversation(
        userId: asInt(json['user_id']),
        name: asString(json['full_name'], 'Invyte member'),
        avatar: asStringOrNull(json['profile_picture']),
        userType: asString(json['user_type'], 'consumer'),
        lastMessage: asStringOrNull(json['last_message']),
        lastMessageAt: asDateTime(json['last_message_time']),
        unreadCount: asInt(json['unread_count']),
      );

  static DirectMessage message(Json json) => DirectMessage(
        id: asInt(json['id']),
        senderId: asInt(json['sender_id'] ?? json['senderId']),
        receiverId: asInt(json['receiver_id'] ?? json['receiverId']),
        message: asString(json['message']),
        isRead: asBool(json['is_read']),
        createdAt: asDateTime(json['created_at']) ?? DateTime.now(),
      );
}
