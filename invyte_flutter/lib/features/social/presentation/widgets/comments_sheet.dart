import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/social.dart';
import '../providers/social_providers.dart';

Future<void> showCommentsSheet(BuildContext context, {required Post post, int? feedKey}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _CommentsSheet(post: post, feedKey: feedKey),
  );
}

class _CommentsSheet extends ConsumerStatefulWidget {
  const _CommentsSheet({required this.post, required this.feedKey});

  final Post post;
  final int? feedKey;

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(socialRepositoryProvider).addComment(widget.post.id, text);
      _controller.clear();
      ref.invalidate(commentsProvider(widget.post.id));
      ref.read(feedProvider(widget.feedKey).notifier).commentAdded(widget.post.id);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final comments = ref.watch(commentsProvider(widget.post.id));
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          children: [
            Text('Comments', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            const Divider(),
            Expanded(
              child: AsyncValueView(
                value: comments,
                onRetry: () => ref.invalidate(commentsProvider(widget.post.id)),
                data: (List<Comment> items) => items.isEmpty
                    ? const EmptyState(
                        icon: Icons.mode_comment_outlined,
                        title: 'No comments yet',
                        message: 'Start the conversation.',
                        compact: true,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 16),
                        itemBuilder: (_, i) {
                          final c = items[i];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              UserAvatar(name: c.authorName, url: c.authorAvatar, size: 36),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(c.authorName, style: theme.textTheme.titleSmall),
                                        const SizedBox(width: 6),
                                        Text(Fmt.relative(c.createdAt),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(c.content),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ),
            const Divider(),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          hintText: 'Add a comment…',
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    IconButton.filled(
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox.square(
                              dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
