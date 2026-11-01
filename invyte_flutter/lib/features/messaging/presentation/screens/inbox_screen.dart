import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/message.dart';
import '../providers/message_providers.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);
    final isVendor = ref.watch(currentUserProvider)?.isVendor ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: AsyncValueView(
        value: conversations,
        onRetry: () => ref.invalidate(conversationsProvider),
        data: (List<Conversation> list) => RefreshIndicator(
          onRefresh: () => ref.refresh(conversationsProvider.future),
          child: list.isEmpty
              ? ListView(children: [
                  EmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'No conversations yet',
                    message: isVendor
                        ? 'Customers who message you will appear here.'
                        : 'Message a vendor to ask questions before you book.',
                    actionLabel: isVendor ? null : 'Find vendors',
                    onAction: isVendor ? null : () => context.go(Routes.discover),
                  ),
                ])
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(indent: 84),
                  itemBuilder: (_, i) => _ConversationTile(conversation: list[i]),
                ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = conversation;
    final unread = c.unreadCount > 0;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      onTap: () => context.push(Routes.chat(c.userId, name: c.name, avatar: c.avatar)),
      leading: UserAvatar(name: c.name, url: c.avatar, size: 52),
      title: Row(
        children: [
          Flexible(
            child: Text(c.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: unread ? FontWeight.w800 : FontWeight.w600)),
          ),
          if (c.isVendor) ...[
            const SizedBox(width: 6),
            const StatusChip(label: 'Vendor', color: AppColors.violet, dense: true),
          ],
        ],
      ),
      subtitle: Text(
        c.lastMessage ?? 'Say hello',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: unread ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
          fontWeight: unread ? FontWeight.w600 : null,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(Fmt.relative(c.lastMessageAt),
              style: theme.textTheme.labelSmall?.copyWith(
                color: unread ? AppColors.primary : theme.colorScheme.onSurfaceVariant,
              )),
          const SizedBox(height: 6),
          if (unread)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(100)),
              child: Text('${c.unreadCount}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
            ),
        ],
      ),
    );
  }
}
