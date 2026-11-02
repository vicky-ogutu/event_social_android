import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/realtime/realtime_service.dart';
import '../../../../core/utils/json.dart';
import '../../domain/entities/livestream.dart';

/// Live video through LiveKit: the host publishes once and LiveKit delivers it
/// to every viewer. Socket.IO only carries presence, which is what keeps the
/// viewer count and the host's on-air time. In demo mode there is no server to
/// connect to, so [LiveJoinInfo.isDemo] sessions stay local.

/// The organizer's side.
class LiveBroadcast {
  LiveBroadcast({required this.realtime, required this.livestreamId, required this.joinInfo});

  final RealtimeService realtime;
  final int livestreamId;
  final LiveJoinInfo joinInfo;

  final viewerCount = ValueNotifier<int>(0);
  final micEnabled = ValueNotifier<bool>(true);
  LocalVideoTrack? cameraTrack;

  Room? _room;
  CameraPosition _position = CameraPosition.front;
  final _subscriptions = <StreamSubscription<Object?>>[];
  bool _disposed = false;

  /// Opens the front camera (prompts for permission).
  Future<void> openCamera() async {
    if (cameraTrack != null) return;
    try {
      cameraTrack = await LocalVideoTrack.createCameraTrack(
        const CameraCaptureOptions(cameraPosition: CameraPosition.front, params: VideoParametersPresets.h720_169),
      );
    } catch (_) {
      throw const Failure('Allow camera and microphone access to go live.');
    }
  }

  Future<void> goLive() async {
    await openCamera();
    if (!joinInfo.isDemo) {
      final room = Room();
      _room = room;
      try {
        await room.connect(joinInfo.url, joinInfo.token);
        await room.localParticipant?.publishVideoTrack(cameraTrack!);
        await room.localParticipant?.setMicrophoneEnabled(true);
      } catch (_) {
        throw const Failure('Could not start the broadcast. Check your connection and try again.');
      }
    }
    _subscriptions
      ..add(realtime.on('live:viewers').listen((d) => viewerCount.value = asInt(d['count'])))
      ..add(realtime.reconnected.listen((_) => _announce().catchError((Object _) {})));
    await _announce();
  }

  /// Starts the on-air clock; repeated after a dropped socket reconnects.
  Future<void> _announce() async {
    final ack = await realtime.request('live:host', {'livestreamId': livestreamId});
    if (ack['error'] != null) throw Failure(asString(ack['error']));
  }

  Future<void> toggleMic() async {
    final enabled = !micEnabled.value;
    await _room?.localParticipant?.setMicrophoneEnabled(enabled);
    micEnabled.value = enabled;
  }

  Future<void> switchCamera() async {
    _position = _position.switched();
    await cameraTrack?.setCameraPosition(_position);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    realtime.send('live:leave', {'livestreamId': livestreamId});
    for (final s in _subscriptions) {
      await s.cancel();
    }
    await _room?.disconnect();
    await _room?.dispose();
    await cameraTrack?.stop();
    cameraTrack = null;
  }
}

enum ViewerState { connecting, waitingForHost, playing, hostLeft }

/// A guest watching the broadcast.
class LiveViewer {
  LiveViewer({required this.realtime, required this.livestreamId, required this.joinInfo});

  final RealtimeService realtime;
  final int livestreamId;
  final LiveJoinInfo joinInfo;

  final state = ValueNotifier<ViewerState>(ViewerState.connecting);
  final remoteVideo = ValueNotifier<VideoTrack?>(null);
  final viewerCount = ValueNotifier<int>(0);

  Room? _room;
  EventsListener<RoomEvent>? _roomEvents;
  final _subscriptions = <StreamSubscription<Object?>>[];
  bool _disposed = false;

  Future<void> join() async {
    _subscriptions
      ..add(realtime.on('live:viewers').listen((d) => viewerCount.value = asInt(d['count'])))
      ..add(realtime.on('live:host-ready').listen((_) => _showVideoState()))
      ..add(realtime.on('live:host-left').listen((_) => _set(ViewerState.hostLeft)))
      ..add(realtime.reconnected.listen((_) => _announce().catchError((Object _) => false)));
    final hostOnline = await _announce();
    _set(hostOnline ? ViewerState.connecting : ViewerState.waitingForHost);
    await _connectMedia();
  }

  /// Registers this viewer, returning whether the host is on air.
  Future<bool> _announce() async {
    final ack = await realtime.request('live:join', {'livestreamId': livestreamId});
    if (ack['error'] != null) throw Failure(asString(ack['error']));
    return asBool(ack['hostOnline']);
  }

  Future<void> _connectMedia() async {
    if (joinInfo.isDemo) return;
    final room = Room();
    _room = room;
    _roomEvents = room.createListener()
      ..on<TrackSubscribedEvent>((event) {
        final track = event.track;
        if (track is VideoTrack) {
          remoteVideo.value = track;
          _set(ViewerState.playing);
        }
      })
      ..on<TrackUnsubscribedEvent>((event) {
        if (event.track == remoteVideo.value) {
          remoteVideo.value = null;
          _set(ViewerState.waitingForHost);
        }
      });
    try {
      await room.connect(joinInfo.url, joinInfo.token);
    } catch (_) {
      throw const Failure('Could not connect to the broadcast. It may be full, or your connection dropped.');
    }
  }

  void _showVideoState() => _set(remoteVideo.value == null ? ViewerState.connecting : ViewerState.playing);

  void _set(ViewerState next) {
    if (!_disposed) state.value = next;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    realtime.send('live:leave', {'livestreamId': livestreamId});
    for (final s in _subscriptions) {
      await s.cancel();
    }
    await _roomEvents?.dispose();
    await _room?.disconnect();
    await _room?.dispose();
  }
}
