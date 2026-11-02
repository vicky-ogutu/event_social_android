import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../data/datasources/event_remote_data_source.dart';
import '../../data/repositories/event_repository_impl.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  ref.watch(sessionScopeProvider);
  return EventRepositoryImpl(EventRemoteDataSource(ref.watch(apiClientProvider)));
});

/// Events the signed-in user organises, soonest first.
final myEventsProvider = FutureProvider<List<Event>>((ref) async {
  final page = await ref.watch(eventRepositoryProvider).myEvents();
  return [...page.items]..sort((a, b) {
      if (a.date == null || b.date == null) return 0;
      return a.date!.compareTo(b.date!);
    });
});

final upcomingMyEventsProvider = Provider<AsyncValue<List<Event>>>((ref) {
  return ref.watch(myEventsProvider).whenData((events) => events.where((e) => !e.isPast).toList());
});

/// Public events, optionally filtered by a search term.
final discoverEventsProvider = FutureProvider.family<List<Event>, EventQuery>((ref, query) async {
  final page = await ref.watch(eventRepositoryProvider).discover(search: query.search);
  return page.items;
});

final liveEventsProvider = Provider<AsyncValue<List<Event>>>((ref) {
  return ref.watch(discoverEventsProvider(const EventQuery())).whenData((e) => e.where((x) => x.isLive).toList());
});

final eventDetailProvider = FutureProvider.autoDispose.family<Event, int>((ref, id) {
  return ref.watch(eventRepositoryProvider).getEvent(id);
});

/// Refreshes every cached event list after a mutation.
void invalidateEvents(WidgetRef ref, {int? eventId}) {
  ref.invalidate(myEventsProvider);
  ref.invalidate(discoverEventsProvider);
  if (eventId != null) ref.invalidate(eventDetailProvider(eventId));
}
