import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/message_remote_data_source.dart';
import '../../data/repositories/message_repository_impl.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/message_repository.dart';

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  ref.watch(sessionScopeProvider);
  return MessageRepositoryImpl(
    MessageRemoteDataSource(ref.watch(apiClientProvider)),
    ref.watch(realtimeProvider),
  );
});

final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final repository = ref.watch(messageRepositoryProvider);
  // Refresh the inbox whenever a new message arrives.
  final subscription = repository.watchIncoming().listen((_) => ref.invalidateSelf());
  ref.onDispose(subscription.cancel);
  return repository.conversations();
});

final unreadCountProvider = Provider<int>((ref) {
  final conversations = ref.watch(conversationsProvider).value ?? const [];
  return conversations.fold(0, (sum, c) => sum + c.unreadCount);
});

final directChatProvider =
    AsyncNotifierProvider.autoDispose.family<DirectChatNotifier, List<DirectMessage>, int>(DirectChatNotifier.new);

class DirectChatNotifier extends AsyncNotifier<List<DirectMessage>> {
  DirectChatNotifier(this.otherUserId);

  final int otherUserId;

  int? get _myId => ref.read(currentUserProvider)?.id;

  @override
  Future<List<DirectMessage>> build() async {
    final repository = ref.watch(messageRepositoryProvider);
    final subscription = repository.watchIncoming().listen((message) {
      final me = _myId;
      if (me != null && message.involves(me, otherUserId)) _append(message);
    });
    ref.onDispose(subscription.cancel);
    final thread = await repository.thread(otherUserId);
    // Opening a thread marks it read server-side; refresh badge counts.
    ref.invalidate(conversationsProvider);
    return thread;
  }

  void _append(DirectMessage message) {
    final current = state.value ?? const [];
    if (current.any((m) => m.id == message.id)) return;
    state = AsyncData([...current, message]);
  }

  Future<void> send(String text) async {
    final message = await ref.read(messageRepositoryProvider).send(receiverId: otherUserId, message: text);
    _append(message);
    ref.invalidate(conversationsProvider);
  }
}
