import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/chat_widgets.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../domain/entities/social.dart';
import '../providers/social_providers.dart';

class EventChatScreen extends ConsumerWidget {
  const EventChatScreen({super.key, required this.eventId});

  final int eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(eventChatProvider(eventId));
    final event = ref.watch(eventDetailProvider(eventId)).value;
    final myId = ref.watch(currentUserProvider)?.id;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event?.name ?? 'Guest chat', maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('Guest chat',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: AsyncValueView(
              value: messages,
              onRetry: () => ref.invalidate(eventChatProvider(eventId)),
              loading: const Center(child: CircularProgressIndicator()),
              data: (List<EventChatMessage> list) => list.isEmpty
                  ? const EmptyState(
                      icon: Icons.forum_rounded,
                      title: 'Say hello 👋',
                      message: 'Messages here are visible to everyone at this event.',
                    )
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final index = list.length - 1 - i;
                        final m = list[index];
                        final previous = index > 0 ? list[index - 1] : null;
                        return Column(
                          children: [
                            if (m.createdAt != null && !isSameDay(previous?.createdAt, m.createdAt))
                              DayDivider(date: m.createdAt!),
                            MessageBubble(
                              text: m.message,
                              mine: m.userId == myId,
                              time: m.createdAt,
                              authorName: m.authorName,
                              authorAvatar: m.authorAvatar,
                              showAuthor: true,
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ),
          ChatInput(
            hint: 'Message everyone…',
            onSend: (text) async {
              try {
                await ref.read(eventChatProvider(eventId).notifier).send(text);
              } catch (e) {
                if (context.mounted) showErrorSnack(context, e);
                rethrow;
              }
            },
          ),
        ],
      ),
    );
  }
}
