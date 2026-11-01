import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/social.dart';
import '../providers/social_providers.dart';
import '../widgets/post_card.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedProvider(null));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moments'),
        actions: [
          IconButton(
            tooltip: 'Share a moment',
            onPressed: () => context.push(Routes.newPost),
            icon: const Icon(Icons.add_box_outlined),
          ),
        ],
      ),
      body: AsyncValueView(
        value: feed,
        onRetry: () => ref.invalidate(feedProvider(null)),
        loading: const SkeletonList(itemHeight: 320),
        data: (List<Post> posts) => RefreshIndicator(
          onRefresh: () => ref.read(feedProvider(null).notifier).refresh(),
          child: posts.isEmpty
              ? ListView(children: [
                  EmptyState(
                    icon: Icons.dynamic_feed_rounded,
                    title: 'No moments yet',
                    message: 'Share photos and updates from your events.',
                    actionLabel: 'Share a moment',
                    onAction: () => context.push(Routes.newPost),
                  ),
                ])
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: posts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (_, i) => PostCard(post: posts[i], feedKey: null),
                ),
        ),
      ),
    );
  }
}
