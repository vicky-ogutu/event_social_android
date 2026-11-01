import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../../events/presentation/widgets/event_cards.dart';

/// Lets an organizer pick which of their events to broadcast.
class GoLiveScreen extends ConsumerWidget {
  const GoLiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(upcomingMyEventsProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Go live')),
      body: AsyncValueView(
        value: events,
        onRetry: () => ref.invalidate(myEventsProvider),
        data: (List<Event> list) => list.isEmpty
            ? EmptyState(
                icon: Icons.live_tv_rounded,
                title: 'No events to stream',
                message: 'Create an event first, then broadcast it to guests anywhere.',
                actionLabel: 'Create event',
                onAction: () => context.push(Routes.newEvent),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                children: [
                  Text(
                    'Choose an event to broadcast. Guests can watch, react and chat in real time.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  for (final e in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: EventListTile(
                        event: e,
                        trailing: IconButton.filled(
                          style: IconButton.styleFrom(backgroundColor: e.isLive ? AppColors.live : AppColors.primary),
                          onPressed: () => context.push(Routes.live(e.id)),
                          icon: const Icon(Icons.videocam_rounded, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
