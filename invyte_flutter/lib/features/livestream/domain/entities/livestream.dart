enum StreamStatus {
  scheduled,
  live,
  ended;

  static StreamStatus parse(String? value) => switch (value) {
        'live' => live,
        'ended' || 'failed' => ended,
        _ => scheduled,
      };
}

/// A broadcast attached to an event. Its id is distinct from the event id.
class Livestream {
  const Livestream({
    required this.id,
    required this.eventId,
    required this.status,
    this.price = 0,
    this.isHost = false,
    this.hasAccess = false,
    this.viewCount = 0,
  });

  final int id;
  final int eventId;
  final StreamStatus status;
  final double price;
  final bool isHost;
  final bool hasAccess;
  final int viewCount;

  bool get isLive => status == StreamStatus.live;
  bool get isFree => price <= 0;
}

/// What a device needs to join a stream's video room.
class LiveJoinInfo {
  const LiveJoinInfo({required this.url, required this.token});

  final String url;
  final String token;

  /// The demo backend has no video server.
  bool get isDemo => url.isEmpty;
}

/// Result of asking for a stream pass.
sealed class StreamPass {
  const StreamPass();
}

class StreamPassGranted extends StreamPass {
  const StreamPassGranted();
}

class StreamPassPaymentRequired extends StreamPass {
  const StreamPassPaymentRequired({required this.clientSecret, required this.paymentIntentId});

  final String clientSecret;
  final String paymentIntentId;
}
