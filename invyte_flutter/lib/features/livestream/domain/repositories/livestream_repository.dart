import '../entities/livestream.dart';

abstract interface class LivestreamRepository {
  /// The event's scheduled or live broadcast, or `null` if there is none.
  Future<Livestream?> forEvent(int eventId);

  /// Creates the event's broadcast (organizer only), or returns the existing one.
  Future<Livestream> prepare(int eventId, {double price = 0});

  Future<void> start(int livestreamId);

  Future<void> end(int livestreamId);

  Future<StreamPass> purchase(int livestreamId);

  /// Finalises a paid pass after the payment sheet succeeds.
  Future<void> confirmPurchase({required int livestreamId, required String paymentIntentId});
}
