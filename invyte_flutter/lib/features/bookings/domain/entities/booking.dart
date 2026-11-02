enum BookingStatus {
  pending,
  confirmed,
  completed,
  rejected,
  cancelled,
  unknown;

  static BookingStatus parse(String? value) => switch (value?.toLowerCase()) {
        'pending' => pending,
        'confirmed' || 'accepted' || 'in_progress' => confirmed,
        'completed' => completed,
        'rejected' || 'declined' => rejected,
        'cancelled' || 'canceled' => cancelled,
        _ => unknown,
      };

  String get label => switch (this) {
        pending => 'Awaiting vendor',
        confirmed => 'Confirmed',
        completed => 'Completed',
        rejected => 'Declined',
        cancelled => 'Cancelled',
        unknown => 'Processing',
      };

  bool get isClosed => this == rejected || this == cancelled;
}

class Booking {
  const Booking({
    required this.id,
    required this.reference,
    required this.eventId,
    required this.serviceId,
    required this.vendorId,
    required this.consumerId,
    required this.status,
    required this.paymentStatus,
    this.bookingDate,
    this.serviceDate,
    this.serviceTime = '',
    this.quantity = 1,
    this.agreedPrice = 0,
    this.serviceFee = 0,
    this.taxAmount = 0,
    this.totalAmount = 0,
    this.amountPaid = 0,
    this.vendorPaymentStatus = 'pending',
    this.specialRequests,
    this.eventName,
    this.vendorName,
    this.serviceName,
    this.consumerName,
  });

  final int id;
  final String reference;
  final int eventId;
  final int serviceId;
  final int vendorId;
  final int consumerId;
  final DateTime? bookingDate;
  final DateTime? serviceDate;
  final String serviceTime;
  final int quantity;
  final double agreedPrice;
  final double serviceFee;
  final double taxAmount;
  final double totalAmount;
  final double amountPaid;
  final String paymentStatus;
  final String vendorPaymentStatus;
  final BookingStatus status;
  final String? specialRequests;
  final String? eventName;
  final String? vendorName;
  final String? serviceName;
  final String? consumerName;

  bool get isPaid =>
      const {'paid', 'completed', 'succeeded'}.contains(paymentStatus) ||
      (totalAmount > 0 && amountPaid >= totalAmount);

  double get balanceDue => (totalAmount - amountPaid).clamp(0, double.infinity);
}

class BookingDraft {
  const BookingDraft({
    required this.eventId,
    required this.serviceId,
    required this.serviceDate,
    required this.serviceTime,
    this.quantity = 1,
    this.specialRequests,
  });

  final int eventId;
  final int serviceId;
  final DateTime serviceDate;
  final String serviceTime;
  final int quantity;
  final String? specialRequests;
}

class PaymentIntent {
  const PaymentIntent({required this.id, required this.clientSecret});

  final String id;
  final String clientSecret;
}
