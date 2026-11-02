import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invyte/core/di/core_providers.dart';
import 'package:invyte/core/storage/token_store.dart';
import 'package:invyte/features/bookings/data/models/booking_mapper.dart';
import 'package:invyte/features/bookings/presentation/widgets/booking_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pump(WidgetTester tester, Map<String, dynamic> json) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final tokens = await TokenStore.open(prefs);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        tokenStoreProvider.overrideWithValue(tokens),
      ],
      child: MaterialApp(
        home: Scaffold(body: VendorBookingActions(booking: BookingMapper.fromJson(json))),
      ),
    ));
  }

  testWidgets('an unpaid booking cannot be accepted yet', (tester) async {
    await pump(tester, {'id': 1, 'booking_status': 'pending', 'payment_status': 'pending', 'total_amount': 100});
    expect(find.text('Accept'), findsNothing);
    final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Awaiting payment'));
    expect(button.onPressed, isNull);
  });

  testWidgets('a paid booking can be accepted', (tester) async {
    await pump(tester, {'id': 1, 'booking_status': 'pending', 'payment_status': 'completed', 'total_amount': 100});
    final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Accept'));
    expect(button.onPressed, isNotNull);
  });
}
