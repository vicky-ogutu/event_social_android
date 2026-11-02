import 'package:flutter_test/flutter_test.dart';
import 'package:invyte/features/bookings/data/models/booking_mapper.dart';

void main() {
  test('reads the vendor name under either API spelling', () {
    expect(BookingMapper.fromJson({'id': 1, 'vendor_name': 'A'}).vendorName, 'A');
    expect(BookingMapper.fromJson({'id': 1, 'vendor_business_name': 'B'}).vendorName, 'B');
  });
}
