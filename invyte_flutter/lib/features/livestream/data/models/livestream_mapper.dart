import '../../../../core/utils/json.dart';
import '../../domain/entities/livestream.dart';

abstract final class LivestreamMapper {
  static Livestream fromJson(Json json) => Livestream(
        id: asInt(json['id']),
        eventId: asInt(json['event_id']),
        status: StreamStatus.parse(asStringOrNull(json['stream_status'])),
        price: asDouble(json['pay_per_view_price']),
        isHost: asBool(json['is_host']),
        hasAccess: asBool(json['has_access']),
        viewCount: asInt(json['view_count']),
      );

  static StreamPass pass(Json json) {
    final secret = asStringOrNull(json['client_secret'] ?? json['clientSecret']);
    if (secret == null) return const StreamPassGranted();
    return StreamPassPaymentRequired(
      clientSecret: secret,
      paymentIntentId: asString(json['payment_intent_id'] ?? json['paymentIntentId']),
    );
  }
}
