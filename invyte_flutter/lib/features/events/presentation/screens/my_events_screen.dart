import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/event.dart';
import '../providers/event_providers.dart';
import '../widgets/event_cards.dart';

class MyEventsScreen extends ConsumerWidget {
  const MyEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(myEventsProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My events'),
          bottom: const TabBar(tabs: [Tab(text: 'Upcoming'), Tab(text: 'Past')]),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push(Routes.newEvent),
          icon: const Icon(Icons.add_rounded),
          label: const Text('New event'),
        ),
        body: AsyncValueView(
          value: events,
          onRetry: () => ref.invalidate(myEventsProvider),
          data: (List<Event> all) => TabBarView(
            children: [
              _EventList(events: all.where((e) => !e.isPast).toList(), empty: 'No upcoming events'),
              _EventList(events: all.where((e) => e.isPast).toList().reversed.toList(), empty: 'No past events'),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventList extends ConsumerWidget {
  const _EventList({required this.events, required this.empty});

  final List<Event> events;
  final String empty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(myEventsProvider.future),
      child: events.isEmpty
          ? ListView(children: [
              EmptyState(
                icon: Icons.event_available_rounded,
                title: empty,
                message: 'Tap "New event" to start planning.',
              ),
            ])
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              itemCount: events.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => EventListTile(event: events[i]),
            ),
    );
  }
}
