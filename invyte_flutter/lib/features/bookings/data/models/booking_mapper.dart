import '../../../../core/utils/json.dart';
import '../../domain/entities/booking.dart';

abstract final class BookingMapper {
  static Booking fromJson(Json json) => Booking(
        id: asInt(json['id']),
        reference: asString(json['booking_reference'], '#${json['id']}'),
        eventId: asInt(json['event_id']),
        serviceId: asInt(json['vendor_service_id']),
        vendorId: asInt(json['vendor_id']),
        consumerId: asInt(json['consumer_id']),
        bookingDate: asDateTime(json['booking_date']),
        serviceDate: asDate(json['service_date']),
        serviceTime: asString(json['service_time']),
        quantity: asInt(json['quantity'], 1),
        agreedPrice: asDouble(json['agreed_price']),
        serviceFee: asDouble(json['service_fee']),
        taxAmount: asDouble(json['tax_amount']),
        totalAmount: asDouble(json['total_amount']),
        amountPaid: asDouble(json['amount_paid']),
        paymentStatus: asString(json['payment_status'], 'pending'),
        vendorPaymentStatus: asString(json['vendor_payment_status'], 'pending'),
        status: BookingStatus.parse(asStringOrNull(json['booking_status'])),
        specialRequests: asStringOrNull(json['special_requests']),
        eventName: asStringOrNull(json['event_name']),
        vendorName: asStringOrNull(json['vendor_name'] ?? json['vendor_business_name']),
        serviceName: asStringOrNull(json['service_name']),
        consumerName: asStringOrNull(json['consumer_name']),
      );

  static Json toJson(BookingDraft draft) => {
        'event_id': draft.eventId,
        'vendor_service_id': draft.serviceId,
        'service_date': toApiDate(draft.serviceDate),
        'service_time': draft.serviceTime,
        'quantity': draft.quantity,
        'special_requests': draft.specialRequests,
      };

  /// The API uses both `client_secret` and `clientSecret` spellings.
  static PaymentIntent paymentIntent(Json json) => PaymentIntent(
        id: asString(json['payment_intent_id'] ?? json['paymentIntentId']),
        clientSecret: asString(json['client_secret'] ?? json['clientSecret']),
      );
}
