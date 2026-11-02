import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../utils/json.dart';

/// Real-time push channel. Payloads are raw JSON so that each feature's
/// data layer owns the mapping to its own entities.
abstract interface class RealtimeService {
  Stream<Json> get eventMessages;
  Stream<Json> get privateMessages;

  /// Fires when the connection comes back after a drop.
  Stream<void> get reconnected;

  void connect();
  void disconnect();
  void joinEvent(int eventId);
  void leaveEvent(int eventId);

  /// Fire-and-forget event.
  void send(String event, Json data);

  /// Emits [event] and waits for the server's acknowledgement payload.
  Future<Json> request(String event, Json data, {Duration timeout = const Duration(seconds: 10)});

  /// Messages the server pushes for [event].
  Stream<Json> on(String event);
}

/// Socket.IO implementation matching the Node backend's events.
class SocketRealtimeService implements RealtimeService {
  SocketRealtimeService({required this.url, required this.tokenReader});

  final String url;

  /// Read on every connect/reconnect, so renewed access tokens are picked up.
  final String? Function() tokenReader;

  io.Socket? _socket;
  final _eventMessages = StreamController<Json>.broadcast();
  final _privateMessages = StreamController<Json>.broadcast();
  final _channels = <String, StreamController<Json>>{};
  final _joinedEvents = <int>{};
  final _reconnected = StreamController<void>.broadcast();
  bool _connectedBefore = false;

  @override
  Stream<void> get reconnected => _reconnected.stream;

  @override
  Stream<Json> get eventMessages => _eventMessages.stream;

  @override
  Stream<Json> get privateMessages => _privateMessages.stream;

  @override
  void connect() {
    if (_socket != null || tokenReader() == null) return;
    final socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableReconnection()
          .setReconnectionAttempts(60)
          .setReconnectionDelay(1000)
          .disableAutoConnect()
          .build(),
    );
    socket.auth = (void Function(Map<String, dynamic>) send) => send({'token': tokenReader()});
    socket
      ..on('new-message', (data) => _eventMessages.add(asJson(data)))
      ..on('new-private-message', (data) => _privateMessages.add(asJson(data)))
      // Rejoin rooms after a reconnect.
      ..onConnect((_) {
        for (final id in _joinedEvents) {
          socket.emit('join-event', id);
        }
        if (_connectedBefore) _reconnected.add(null);
        _connectedBefore = true;
      })
      ..connect();
    for (final event in _channels.keys) {
      _listen(socket, event);
    }
    _socket = socket;
  }

  void _listen(io.Socket socket, String event) {
    socket.on(event, (data) => _channels[event]?.add(asJson(data)));
  }

  @override
  void joinEvent(int eventId) {
    _joinedEvents.add(eventId);
    _socket?.emit('join-event', eventId);
  }

  @override
  void leaveEvent(int eventId) {
    _joinedEvents.remove(eventId);
    _socket?.emit('leave-event', eventId);
  }

  @override
  void send(String event, Json data) => _socket?.emit(event, data);

  @override
  Future<Json> request(String event, Json data, {Duration timeout = const Duration(seconds: 10)}) {
    final socket = _socket;
    if (socket == null) return Future.error(StateError('Not connected'));
    final completer = Completer<Json>();
    socket.emitWithAck(event, data, ack: (response) {
      if (!completer.isCompleted) completer.complete(asJson(response));
    });
    return completer.future.timeout(timeout);
  }

  @override
  Stream<Json> on(String event) {
    final existing = _channels[event];
    if (existing != null) return existing.stream;
    final controller = StreamController<Json>.broadcast();
    _channels[event] = controller;
    final socket = _socket;
    if (socket != null) _listen(socket, event);
    return controller.stream;
  }

  @override
  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _joinedEvents.clear();
    _eventMessages.close();
    _privateMessages.close();
    _reconnected.close();
    for (final c in _channels.values) {
      c.close();
    }
    _channels.clear();
  }
}
