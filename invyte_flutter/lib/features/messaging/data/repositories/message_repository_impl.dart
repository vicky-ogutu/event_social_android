import '../../../../core/error/failure.dart';
import '../../../../core/realtime/realtime_service.dart';
import '../../../../core/utils/json.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/message_repository.dart';
import '../datasources/message_remote_data_source.dart';
import '../models/message_mapper.dart';

class MessageRepositoryImpl implements MessageRepository {
  const MessageRepositoryImpl(this._remote, this._realtime);

  final MessageRemoteDataSource _remote;
  final RealtimeService _realtime;

  @override
  Future<List<Conversation>> conversations() =>
      guard(() async => asList(await _remote.conversations(), MessageMapper.conversation));

  @override
  Future<List<DirectMessage>> thread(int userId) => guard(() async {
        final messages = asList(await _remote.thread(userId), MessageMapper.message);
        messages.sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
        return messages;
      });

  @override
  Future<DirectMessage> send({required int receiverId, required String message}) =>
      guard(() async => MessageMapper.message(await _remote.send(receiverId, message)));

  @override
  Stream<DirectMessage> watchIncoming() => _realtime.privateMessages.map(MessageMapper.message);
}
