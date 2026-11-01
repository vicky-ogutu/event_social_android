import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../data/datasources/social_remote_data_source.dart';
import '../../data/repositories/social_repository_impl.dart';
import '../../domain/entities/social.dart';
import '../../domain/repositories/social_repository.dart';

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  ref.watch(sessionScopeProvider);
  return SocialRepositoryImpl(
    SocialRemoteDataSource(ref.watch(apiClientProvider)),
    ref.watch(realtimeProvider),
  );
});

/// The social feed — global when the argument is `null`, otherwise scoped to
/// one event.
final feedProvider = AsyncNotifierProvider.family<FeedNotifier, List<Post>, int?>(FeedNotifier.new);

class FeedNotifier extends AsyncNotifier<List<Post>> {
  FeedNotifier(this.eventId);

  final int? eventId;

  SocialRepository get _repository => ref.read(socialRepositoryProvider);

  @override
  Future<List<Post>> build() => ref.watch(socialRepositoryProvider).feed(eventId: eventId);

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => _repository.feed(eventId: eventId));
  }

  /// Optimistic like toggle; rolls back if the request fails.
  Future<void> toggleLike(int postId) async {
    final before = state.value;
    if (before == null) return;
    state = AsyncData([
      for (final p in before)
        if (p.id == postId)
          p.copyWith(isLiked: !p.isLiked, likeCount: p.likeCount + (p.isLiked ? -1 : 1))
        else
          p,
    ]);
    try {
      await _repository.toggleLike(postId);
    } catch (_) {
      state = AsyncData(before);
      rethrow;
    }
  }

  Future<void> publish({required int eventId, required String content, List<String> mediaUrls = const []}) async {
    final post = await _repository.createPost(eventId: eventId, content: content, mediaUrls: mediaUrls);
    final current = state.value ?? const [];
    if (this.eventId == null || this.eventId == eventId) state = AsyncData([post, ...current]);
  }

  void commentAdded(int postId) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData([
      for (final p in current) p.id == postId ? p.copyWith(commentCount: p.commentCount + 1) : p,
    ]);
  }
}

final commentsProvider = FutureProvider.autoDispose.family<List<Comment>, int>(
  (ref, postId) => ref.watch(socialRepositoryProvider).comments(postId),
);

/// Event group chat: initial history over HTTP, then live updates.
final eventChatProvider =
    AsyncNotifierProvider.autoDispose.family<EventChatNotifier, List<EventChatMessage>, int>(EventChatNotifier.new);

class EventChatNotifier extends AsyncNotifier<List<EventChatMessage>> {
  EventChatNotifier(this.eventId);

  final int eventId;

  @override
  Future<List<EventChatMessage>> build() async {
    final repository = ref.watch(socialRepositoryProvider);
    final subscription = repository.watchEventChat(eventId).listen(_append);
    ref.onDispose(subscription.cancel);
    return repository.eventChat(eventId);
  }

  void _append(EventChatMessage message) {
    final current = state.value ?? const [];
    if (current.any((m) => m.id == message.id)) return;
    state = AsyncData([...current, message]);
  }

  Future<void> send(String text) async {
    final message = await ref.read(socialRepositoryProvider).sendEventChat(eventId, text);
    _append(message);
  }
}
