import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../social/presentation/providers/social_providers.dart';
import '../../../social/presentation/widgets/post_card.dart';
import '../../domain/entities/event.dart';
import '../providers/event_providers.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final int eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(eventDetailProvider(eventId));
    return Scaffold(
      body: AsyncValueView(
        value: event,
        onRetry: () => ref.invalidate(eventDetailProvider(eventId)),
        loading: const Center(child: CircularProgressIndicator()),
        data: (Event e) => _EventDetailBody(event: e),
      ),
    );
  }
}

class _EventDetailBody extends ConsumerStatefulWidget {
  const _EventDetailBody({required this.event});

  final Event event;

  @override
  ConsumerState<_EventDetailBody> createState() => _EventDetailBodyState();
}

class _EventDetailBodyState extends ConsumerState<_EventDetailBody> {
  late Event _event = widget.event;
  bool _joining = false;

  @override
  void didUpdateWidget(covariant _EventDetailBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    _event = widget.event;
  }

  bool get _isOrganizer => ref.read(currentUserProvider)?.id == _event.organizerId;

  Future<void> _toggleLike() async {
    final before = _event;
    setState(() => _event = _event.copyWith(
          isLiked: !_event.isLiked,
          likeCount: _event.likeCount + (_event.isLiked ? -1 : 1),
        ));
    try {
      final liked = await ref.read(eventRepositoryProvider).toggleLike(_event.id);
      if (liked != _event.isLiked && mounted) {
        setState(() => _event = before.copyWith(isLiked: liked));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _event = before);
      showErrorSnack(context, e);
    }
  }

  Future<void> _join() async {
    setState(() => _joining = true);
    try {
      final message = await ref.read(eventRepositoryProvider).join(_event.id);
      if (!mounted) return;
      showSnack(context, message);
      invalidateEvents(ref, eventId: _event.id);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _delete() async {
    final ok = await confirmAction(
      context,
      title: 'Delete event?',
      message: 'This permanently removes "${_event.name}" and its guest list.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    try {
      await ref.read(eventRepositoryProvider).delete(_event.id);
      invalidateEvents(ref);
      if (!mounted) return;
      showSnack(context, 'Event deleted');
      context.pop();
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = _event;
    final organizer = _isOrganizer;
    final posts = ref.watch(feedProvider(e.id));

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 320,
              pinned: true,
              stretch: true,
              foregroundColor: Colors.white,
              backgroundColor: AppColors.ink,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              leading: const _CircleButton(child: BackButton(color: Colors.white)),
              actions: [
                _CircleButton(
                  child: IconButton(
                    onPressed: _toggleLike,
                    icon: Icon(e.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: e.isLiked ? AppColors.primary : Colors.white),
                  ),
                ),
                if (organizer)
                  _CircleButton(
                    child: PopupMenuButton<String>(
                      iconColor: Colors.white,
                      onSelected: (v) => v == 'edit' ? context.push(Routes.editEvent(e.id)) : _delete(),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit event')),
                        PopupMenuItem(value: 'delete', child: Text('Delete event')),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground],
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(tag: 'event-cover-${e.id}', child: AppImage(e.coverImage, placeholderSeed: e.name)),
                    const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.scrim)),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (e.isLive) ...[LiveBadge(viewers: Fmt.compact(e.viewCount)), const SizedBox(width: 8)],
                              StatusChip(
                                label: e.isPrivate ? 'Private' : 'Public',
                                icon: e.isPrivate ? Icons.lock_rounded : Icons.public_rounded,
                                color: Colors.white,
                                dense: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(e.name,
                              style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, height: 1.15)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      _Stat(icon: Icons.visibility_rounded, value: Fmt.compact(e.viewCount), label: 'views'),
                      _Stat(icon: Icons.favorite_rounded, value: Fmt.compact(e.likeCount), label: 'likes'),
                      if (e.expectedAttendees != null)
                        _Stat(icon: Icons.groups_rounded, value: Fmt.compact(e.expectedAttendees!), label: 'guests'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Panel(
                    child: Column(
                      children: [
                        InfoRow(
                          icon: Icons.calendar_month_rounded,
                          title: Fmt.date(e.date),
                          subtitle: Fmt.countdown(e.date),
                        ),
                        InfoRow(
                          icon: Icons.schedule_rounded,
                          title: e.endTime == null
                              ? Fmt.time(e.startTime)
                              : '${Fmt.time(e.startTime)} – ${Fmt.time(e.endTime)}',
                          subtitle: 'Local time',
                        ),
                        InfoRow(
                          icon: Icons.place_rounded,
                          title: e.venue ?? 'Venue to be announced',
                          subtitle: 'Venue',
                        ),
                        if (organizer && e.isPrivate && e.accessCode != null)
                          InfoRow(
                            icon: Icons.key_rounded,
                            title: e.accessCode!,
                            subtitle: 'Guest access code',
                            trailing: IconButton(
                              icon: const Icon(Icons.copy_rounded),
                              onPressed: () async {
                                await Clipboard.setData(ClipboardData(text: e.accessCode!));
                                if (context.mounted) showSnack(context, 'Access code copied');
                              },
                            ),
                          ),
                        if (organizer && e.budget != null)
                          InfoRow(
                            icon: Icons.account_balance_wallet_rounded,
                            title: Fmt.money(e.budget!),
                            subtitle: 'Budget',
                          ),
                      ],
                    ),
                  ),
                  if (e.organizerName != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: UserAvatar(name: e.organizerName!, url: e.organizerPic),
                        title: Text(e.organizerName!, style: theme.textTheme.titleSmall),
                        subtitle: const Text('Organizer'),
                        trailing: organizer
                            ? const StatusChip(label: 'You', color: AppColors.primary, dense: true)
                            : IconButton(
                                icon: const Icon(Icons.chat_bubble_outline_rounded),
                                onPressed: () => context.push(
                                  Routes.chat(e.organizerId, name: e.organizerName!, avatar: e.organizerPic),
                                ),
                              ),
                      ),
                    ),
                  ],
                  if (e.description != null) ...[
                    const SizedBox(height: 24),
                    Text('About', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(e.description!, style: theme.textTheme.bodyLarge),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.forum_rounded,
                          label: 'Guest chat',
                          onTap: () => context.push(Routes.eventChat(e.id)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.live_tv_rounded,
                          label: organizer ? (e.isLive ? 'Live studio' : 'Go live') : 'Watch live',
                          highlight: e.isLive,
                          onTap: () => context.push(Routes.live(e.id)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.add_a_photo_rounded,
                          label: 'Post moment',
                          onTap: () => context.push('${Routes.newPost}?eventId=${e.id}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Moments', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  ...posts.when(
                    data: (items) => items.isEmpty
                        ? [
                            const Card(
                              child: EmptyState(
                                icon: Icons.photo_camera_back_rounded,
                                title: 'No moments yet',
                                message: 'Be the first to share something from this event.',
                                compact: true,
                              ),
                            ),
                          ]
                        : [
                            for (final p in items)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: PostCard(post: p, feedKey: e.id),
                              ),
                          ],
                    loading: () => [const Skeleton(height: 200, radius: 20)],
                    error: (err, _) => [Text(err.toString())],
                  ),
                ],
              ),
            ),
          ],
        ),
        // Only guests who already joined can open a private event.
        if (!organizer && !e.isPrivate)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(top: BorderSide(color: theme.colorScheme.outline)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(Fmt.date(e.date), style: theme.textTheme.titleSmall),
                          Text(e.hasJoined ? "You're going" : 'Free to join',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 170,
                      child: PrimaryButton(
                        label: e.hasJoined ? 'Joined' : 'Join event',
                        loading: _joining,
                        onPressed: e.hasJoined ? null : _join,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
        child: child,
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(value, style: theme.textTheme.titleSmall),
          const SizedBox(width: 3),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, required this.onTap, this.highlight = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: highlight ? AppColors.live.withValues(alpha: 0.1) : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: highlight ? AppColors.live : AppColors.primary),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
