import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/chat_widgets.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/message.dart';
import '../providers/message_providers.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key, required this.userId, required this.name, this.avatar});

  final int userId;
  final String name;
  final String? avatar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(directChatProvider(userId));
    final myId = ref.watch(currentUserProvider)?.id;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            UserAvatar(name: name, url: avatar, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: AsyncValueView(
              value: messages,
              onRetry: () => ref.invalidate(directChatProvider(userId)),
              loading: const Center(child: CircularProgressIndicator()),
              data: (List<DirectMessage> list) => list.isEmpty
                  ? EmptyState(
                      icon: Icons.waving_hand_rounded,
                      title: 'Start the conversation',
                      message: 'Ask $name about availability, pricing or anything else.',
                    )
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(12),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final index = list.length - 1 - i;
                        final m = list[index];
                        final previous = index > 0 ? list[index - 1] : null;
                        return Column(
                          children: [
                            if (m.createdAt != null && !isSameDay(previous?.createdAt, m.createdAt))
                              DayDivider(date: m.createdAt!),
                            MessageBubble(text: m.message, mine: m.senderId == myId, time: m.createdAt),
                          ],
                        );
                      },
                    ),
            ),
          ),
          ChatInput(
            onSend: (text) async {
              try {
                await ref.read(directChatProvider(userId).notifier).send(text);
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
