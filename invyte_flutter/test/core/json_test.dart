import 'package:flutter_test/flutter_test.dart';
import 'package:invyte/core/utils/json.dart';
import 'package:invyte/features/bookings/data/models/booking_mapper.dart';
import 'package:invyte/features/bookings/domain/entities/booking.dart';
import 'package:invyte/features/events/data/models/event_mapper.dart';

void main() {
  test('lenient readers handle MySQL-style values', () {
    expect(asInt('12'), 12);
    expect(asDouble('4.50'), 4.5);
    expect(asBool(1), isTrue);
    expect(asBool('0'), isFalse);
    expect(asStringOrNull(''), isNull);
  });

  test('asDate ignores the time zone part of ISO timestamps', () {
    expect(asDate('2026-06-01T00:00:00.000Z'), DateTime(2026, 6, 1));
    expect(asDate('2026-06-01'), DateTime(2026, 6, 1));
    expect(toApiDate(DateTime(2026, 1, 9)), '2026-01-09');
  });

  test('EventMapper parses paginated envelopes', () {
    final page = EventMapper.page({
      'data': [
        {'id': '3', 'event_name': 'Launch', 'event_type': 'private', 'is_live': 1, 'start_time': '18:00:00'},
      ],
      'page': 1,
      'pages': 2,
      'total': 21,
    });
    expect(page.items.single.id, 3);
    expect(page.items.single.isPrivate, isTrue);
    expect(page.items.single.isLive, isTrue);
    expect(page.hasMore, isTrue);
  });

  test('payment intents accept camelCase and snake_case keys', () {
    final camel = BookingMapper.paymentIntent({'clientSecret': 'cs', 'paymentIntentId': 'pi'});
    final snake = BookingMapper.paymentIntent({'client_secret': 'cs', 'payment_intent_id': 'pi'});
    expect([camel.clientSecret, camel.id], ['cs', 'pi']);
    expect([snake.clientSecret, snake.id], ['cs', 'pi']);
    expect(BookingMapper.fromJson({'id': 1, 'payment_status': 'completed'}).isPaid, isTrue);
  });

  test('BookingMapper normalises status and payment state', () {
    final booking = BookingMapper.fromJson({
      'id': 1,
      'booking_status': 'confirmed',
      'payment_status': 'pending',
      'total_amount': '100.00',
      'amount_paid': '100.00',
    });
    expect(booking.status, BookingStatus.confirmed);
    expect(booking.isPaid, isTrue);
    expect(booking.balanceDue, 0);
  });
}
