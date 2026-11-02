import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:invyte/core/realtime/realtime_service.dart';
import 'package:invyte/core/utils/json.dart';
import 'package:invyte/features/livestream/data/live/live_sessions.dart';
import 'package:invyte/features/livestream/domain/entities/livestream.dart';

class _FakeRealtime implements RealtimeService {
  final reconnects = StreamController<void>.broadcast();
  final requests = <String>[];
  Json nextAck = {'ok': true, 'hostOnline': true};

  @override
  Stream<void> get reconnected => reconnects.stream;

  @override
  Stream<Json> on(String event) => const Stream.empty();

  @override
  Future<Json> request(String event, Json data, {Duration timeout = const Duration(seconds: 10)}) async {
    requests.add(event);
    return nextAck;
  }

  @override
  void send(String event, Json data) {}

  @override
  Stream<Json> get eventMessages => const Stream.empty();

  @override
  Stream<Json> get privateMessages => const Stream.empty();

  @override
  void connect() {}

  @override
  void disconnect() {}

  @override
  void joinEvent(int eventId) {}

  @override
  void leaveEvent(int eventId) {}
}

void main() {
  test('a viewer asks for the stream again after reconnecting', () async {
    final realtime = _FakeRealtime();
    final viewer = LiveViewer(realtime: realtime, livestreamId: 1, joinInfo: const LiveJoinInfo(url: '', token: ''));
    await viewer.join();
    expect(realtime.requests, ['live:join']);

    realtime.reconnects.add(null);
    await pumpEventQueue();
    expect(realtime.requests, ['live:join', 'live:join']);

    await viewer.dispose();
    realtime.reconnects.add(null);
    await pumpEventQueue();
    expect(realtime.requests, hasLength(2));
  });

  test('a refused viewer sees the reason', () async {
    final realtime = _FakeRealtime()..nextAck = {'error': 'You do not have access to this private event'};
    final viewer = LiveViewer(realtime: realtime, livestreamId: 1, joinInfo: const LiveJoinInfo(url: '', token: ''));
    await expectLater(viewer.join(), throwsA(predicate((e) => '$e'.contains('private event'))));
    await viewer.dispose();
  });
}
