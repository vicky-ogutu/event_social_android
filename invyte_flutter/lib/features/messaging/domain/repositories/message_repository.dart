import '../entities/message.dart';

abstract interface class MessageRepository {
  Future<List<Conversation>> conversations();

  /// Messages exchanged with [userId], oldest first.
  Future<List<DirectMessage>> thread(int userId);

  Future<DirectMessage> send({required int receiverId, required String message});

  /// Incoming direct messages pushed in real time.
  Stream<DirectMessage> watchIncoming();
}
