import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/realtime/realtime_service.dart';
import '../../../../core/utils/json.dart';

/// Peer-to-peer live video over WebRTC.
///
/// The host opens one [RTCPeerConnection] per viewer and sends its camera
/// stream to each. The backend only relays signalling (`live:*` socket
/// events), so there is no media server to run or pay for. Upload bandwidth
/// on the host's device limits a broadcast to roughly 5–10 viewers.

/// One WebRTC connection plus ICE candidates that arrived early.
class _Peer {
  _Peer(this.connection);

  final RTCPeerConnection connection;
  final _pending = <RTCIceCandidate>[];
  bool _hasRemote = false;

  Future<void> setRemote(RTCSessionDescription description) async {
    await connection.setRemoteDescription(description);
    _hasRemote = true;
    for (final c in _pending) {
      await connection.addCandidate(c);
    }
    _pending.clear();
  }

  Future<void> addCandidate(RTCIceCandidate candidate) async {
    if (_hasRemote) {
      await connection.addCandidate(candidate);
    } else {
      _pending.add(candidate);
    }
  }

  Future<void> close() => connection.close();
}

RTCSessionDescription _description(Object? json) {
  final map = asJson(json);
  return RTCSessionDescription(asStringOrNull(map['sdp']), asStringOrNull(map['type']));
}

RTCIceCandidate _candidate(Object? json) {
  final map = asJson(json);
  return RTCIceCandidate(
    asStringOrNull(map['candidate']),
    asStringOrNull(map['sdpMid']),
    asIntOrNull(map['sdpMLineIndex']),
  );
}

Map<String, dynamic> _rtcConfig(List<Map<String, dynamic>> iceServers) =>
    {'iceServers': iceServers, 'sdpSemantics': 'unified-plan'};

/// The organizer's side: camera capture and one connection per viewer.
class LiveBroadcast {
  LiveBroadcast({required this.realtime, required this.livestreamId, required this.iceServers});

  final RealtimeService realtime;
  final int livestreamId;
  final List<Map<String, dynamic>> iceServers;

  final viewerCount = ValueNotifier<int>(0);
  final micEnabled = ValueNotifier<bool>(true);
  MediaStream? localStream;

  final _peers = <String, _Peer>{};
  final _subscriptions = <StreamSubscription<Json>>[];
  bool _disposed = false;

  /// Opens the front camera and microphone (prompts for permission).
  Future<MediaStream> openCamera() async {
    try {
      return localStream ??= await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
          'frameRate': {'ideal': 30},
        },
      });
    } catch (_) {
      throw const Failure('Allow camera and microphone access to go live.');
    }
  }

  /// Announces the broadcast; viewers (waiting or new) each receive an offer.
  Future<void> goLive() async {
    await openCamera();
    _subscriptions
      ..add(realtime.on('live:viewer-joined').listen((d) => _offerTo(asString(d['viewerId']))))
      ..add(realtime.on('live:viewer-left').listen((d) => _closePeer(asString(d['viewerId']))))
      ..add(realtime.on('live:viewers').listen((d) => viewerCount.value = asInt(d['count'])))
      ..add(realtime.on('live:signal').listen(_onSignal));
    final ack = await realtime.request('live:host', {'livestreamId': livestreamId});
    if (ack['error'] != null) throw Failure(asString(ack['error']));
  }

  Future<void> _offerTo(String viewerId) async {
    final stream = localStream;
    if (stream == null || viewerId.isEmpty || _disposed) return;
    await _closePeer(viewerId);
    final connection = await createPeerConnection(_rtcConfig(iceServers));
    final peer = _Peer(connection);
    _peers[viewerId] = peer;
    for (final track in stream.getTracks()) {
      await connection.addTrack(track, stream);
    }
    connection.onIceCandidate = (candidate) {
      if (candidate.candidate == null) return;
      realtime.send('live:signal', {'livestreamId': livestreamId, 'to': viewerId, 'candidate': candidate.toMap()});
    };
    final offer = await connection.createOffer();
    await connection.setLocalDescription(offer);
    realtime.send('live:signal', {'livestreamId': livestreamId, 'to': viewerId, 'description': offer.toMap()});
  }

  Future<void> _onSignal(Json data) async {
    final peer = _peers[asString(data['from'])];
    if (peer == null) return;
    if (data['description'] != null) await peer.setRemote(_description(data['description']));
    if (data['candidate'] != null) await peer.addCandidate(_candidate(data['candidate']));
  }

  Future<void> _closePeer(String viewerId) async => _peers.remove(viewerId)?.close();

  void toggleMic() {
    final enabled = !micEnabled.value;
    for (final track in localStream?.getAudioTracks() ?? const <MediaStreamTrack>[]) {
      track.enabled = enabled;
    }
    micEnabled.value = enabled;
  }

  Future<void> switchCamera() async {
    final tracks = localStream?.getVideoTracks() ?? const <MediaStreamTrack>[];
    if (tracks.isNotEmpty) await Helper.switchCamera(tracks.first);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    realtime.send('live:leave', {'livestreamId': livestreamId});
    for (final s in _subscriptions) {
      await s.cancel();
    }
    for (final peer in _peers.values) {
      await peer.close();
    }
    _peers.clear();
    for (final track in localStream?.getTracks() ?? const <MediaStreamTrack>[]) {
      await track.stop();
    }
    await localStream?.dispose();
    localStream = null;
  }
}

enum ViewerState { connecting, waitingForHost, playing, hostLeft }

/// A guest watching the broadcast.
class LiveViewer {
  LiveViewer({required this.realtime, required this.livestreamId, required this.iceServers});

  final RealtimeService realtime;
  final int livestreamId;
  final List<Map<String, dynamic>> iceServers;

  final state = ValueNotifier<ViewerState>(ViewerState.connecting);
  final remoteStream = ValueNotifier<MediaStream?>(null);
  final viewerCount = ValueNotifier<int>(0);

  _Peer? _peer;
  final _subscriptions = <StreamSubscription<Json>>[];
  bool _disposed = false;

  Future<void> join() async {
    _subscriptions
      ..add(realtime.on('live:signal').listen(_onSignal))
      ..add(realtime.on('live:viewers').listen((d) => viewerCount.value = asInt(d['count'])))
      ..add(realtime.on('live:host-ready').listen((_) => _set(ViewerState.connecting)))
      ..add(realtime.on('live:host-left').listen((_) async {
        await _closePeer();
        _set(ViewerState.hostLeft);
      }));
    final ack = await realtime.request('live:join', {'livestreamId': livestreamId});
    if (ack['error'] != null) throw Failure(asString(ack['error']));
    _set(asBool(ack['hostOnline']) ? ViewerState.connecting : ViewerState.waitingForHost);
  }

  Future<void> _onSignal(Json data) async {
    final from = asString(data['from']);
    final description = data['description'];
    if (description != null && asJson(description)['type'] == 'offer') {
      // A new offer means the host (re)connected: start a fresh connection.
      await _closePeer();
      final connection = await createPeerConnection(_rtcConfig(iceServers));
      final peer = _Peer(connection);
      _peer = peer;
      connection.onTrack = (event) {
        if (event.streams.isEmpty) return;
        remoteStream.value = event.streams.first;
        _set(ViewerState.playing);
      };
      connection.onIceCandidate = (candidate) {
        if (candidate.candidate == null) return;
        realtime.send('live:signal', {'livestreamId': livestreamId, 'to': from, 'candidate': candidate.toMap()});
      };
      connection.onConnectionState = (s) {
        if (s == RTCPeerConnectionState.RTCPeerConnectionStateFailed) _set(ViewerState.waitingForHost);
      };
      await peer.setRemote(_description(description));
      final answer = await connection.createAnswer();
      await connection.setLocalDescription(answer);
      realtime.send('live:signal', {'livestreamId': livestreamId, 'to': from, 'description': answer.toMap()});
    }
    if (data['candidate'] != null) await _peer?.addCandidate(_candidate(data['candidate']));
  }

  void _set(ViewerState next) {
    if (!_disposed) state.value = next;
  }

  Future<void> _closePeer() async {
    remoteStream.value = null;
    await _peer?.close();
    _peer = null;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    realtime.send('live:leave', {'livestreamId': livestreamId});
    for (final s in _subscriptions) {
      await s.cancel();
    }
    await _closePeer();
  }
}
