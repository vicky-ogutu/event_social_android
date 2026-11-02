import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/realtime/realtime_service.dart';
import '../../data/datasources/livestream_remote_data_source.dart';
import '../../data/repositories/livestream_repository_impl.dart';
import '../../data/live/live_sessions.dart';
import '../../domain/entities/livestream.dart';
import '../../domain/repositories/livestream_repository.dart';

final livestreamRepositoryProvider = Provider<LivestreamRepository>((ref) {
  ref.watch(sessionScopeProvider);
  return LivestreamRepositoryImpl(LivestreamRemoteDataSource(ref.watch(apiClientProvider)));
});

/// The broadcast for an event, if one is scheduled or live.
final livestreamForEventProvider = FutureProvider.autoDispose.family<Livestream?, int>(
  (ref, eventId) => ref.watch(livestreamRepositoryProvider).forEvent(eventId),
);

/// Factories for live video sessions; the screen owns and disposes them.
final liveSessionFactoryProvider = Provider<LiveSessionFactory>(
  (ref) => LiveSessionFactory(ref.watch(realtimeProvider)),
);

class LiveSessionFactory {
  const LiveSessionFactory(this._realtime);

  final RealtimeService _realtime;

  LiveBroadcast broadcast(int livestreamId, LiveJoinInfo joinInfo) =>
      LiveBroadcast(realtime: _realtime, livestreamId: livestreamId, joinInfo: joinInfo);

  LiveViewer viewer(int livestreamId, LiveJoinInfo joinInfo) =>
      LiveViewer(realtime: _realtime, livestreamId: livestreamId, joinInfo: joinInfo);
}
