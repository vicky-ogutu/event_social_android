import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invyte/app/app.dart';
import 'package:invyte/core/di/core_providers.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:invyte/core/storage/token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('returning visitor lands on the sign-in screen', (tester) async {
    SharedPreferences.setMockInitialValues({'app.onboarded': true});
    FlutterSecureStorage.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final tokens = await TokenStore.open(prefs);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        tokenStoreProvider.overrideWithValue(tokens),
      ],
      child: const InvyteApp(),
    ));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Event host'), findsOneWidget);
    expect(find.text('Vendor'), findsOneWidget);
  });

  testWidgets('first launch shows onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final tokens = await TokenStore.open(prefs);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        tokenStoreProvider.overrideWithValue(tokens),
      ],
      child: const InvyteApp(),
    ));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Plan unforgettable events'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
