import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/common.dart';
import '../../domain/entities/social.dart';
import '../providers/social_providers.dart';
import 'comments_sheet.dart';

class PostCard extends ConsumerStatefulWidget {
  const PostCard({super.key, required this.post, required this.feedKey});

  final Post post;

  /// Which [feedProvider] owns this post (null = global feed).
  final int? feedKey;

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  int _page = 0;

  Future<void> _like() async {
    try {
      await ref.read(feedProvider(widget.feedKey).notifier).toggleLike(widget.post.id);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            leading: UserAvatar(name: post.authorName, url: post.authorAvatar, size: 42),
            title: Text(post.authorName, style: theme.textTheme.titleSmall),
            subtitle: Text(Fmt.relative(post.createdAt), style: theme.textTheme.bodySmall?.copyWith(color: muted)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (post.isPinned) const Icon(Icons.push_pin_rounded, size: 18, color: AppColors.primary),
                IconButton(
                  tooltip: 'View event',
                  onPressed: () => context.push(Routes.event(post.eventId)),
                  icon: const Icon(Icons.event_rounded),
                ),
              ],
            ),
          ),
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(post.content, style: theme.textTheme.bodyLarge),
            ),
          if (post.mediaUrls.isNotEmpty)
            GestureDetector(
              onDoubleTap: post.isLiked ? null : _like,
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  children: [
                    PageView.builder(
                      itemCount: post.mediaUrls.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (_, i) => AppImage(post.mediaUrls[i], placeholderSeed: '${post.id}-$i'),
                    ),
                    if (post.mediaUrls.length > 1)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(100)),
                          child: Text('${_page + 1}/${post.mediaUrls.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 12, 8),
            child: Row(
              children: [
                _Action(
                  icon: post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: post.isLiked ? AppColors.primary : null,
                  label: Fmt.compact(post.likeCount),
                  onTap: _like,
                ),
                _Action(
                  icon: Icons.mode_comment_outlined,
                  label: Fmt.compact(post.commentCount),
                  onTap: () => showCommentsSheet(context, post: post, feedKey: widget.feedKey),
                ),
                _Action(
                  icon: Icons.link_rounded,
                  label: Fmt.compact(post.shareCount),
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: 'https://invyte.app/events/${post.eventId}'));
                    if (context.mounted) showSnack(context, 'Event link copied');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap, this.color});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(foregroundColor: color ?? Theme.of(context).colorScheme.onSurface),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
        child: Icon(icon, key: ValueKey(icon), size: 22),
      ),
      label: Text(label),
    );
  }
}
