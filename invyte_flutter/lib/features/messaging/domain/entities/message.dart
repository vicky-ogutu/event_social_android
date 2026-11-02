class Conversation {
  const Conversation({
    required this.userId,
    required this.name,
    this.avatar,
    this.userType = 'consumer',
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  final int userId;
  final String name;
  final String? avatar;
  final String userType;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  bool get isVendor => userType == 'vendor';
}

class DirectMessage {
  const DirectMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    this.isRead = false,
    this.createdAt,
  });

  final int id;
  final int senderId;
  final int receiverId;
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  bool involves(int a, int b) => (senderId == a && receiverId == b) || (senderId == b && receiverId == a);
}
