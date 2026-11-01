import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:invyte/app/router.dart';
import 'package:invyte/core/di/core_providers.dart';
import 'package:invyte/core/storage/token_store.dart';
import 'package:invyte/features/home/presentation/screens/vendor_dashboard_screen.dart';
import 'package:invyte/features/vendors/presentation/screens/business_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A newly registered vendor has no business profile yet: the dashboard opens
/// and Business shows an empty form, against a fake of the real API.
void main() {
  Map<String, dynamic>? created;

  http.Response json(Object body, [int status = 200]) =>
      http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});

  Future<void> pumpDashboard(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'app.onboarded': true});
    FlutterSecureStorage.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final tokens = await TokenStore.open(prefs);

    created = null;
    final api = MockClient((request) async {
      if (request.url.path == '/api/vendors/profile' && request.method == 'POST') {
        created = jsonDecode(request.body) as Map<String, dynamic>;
        return json({'success': true, 'data': {'id': 1, 'user_id': 5, ...created!}}, 201);
      }
      return switch (request.url.path) {
        '/api/vendors/profile' when created != null => json({
            'success': true,
            'data': {'id': 1, 'user_id': 5, ...created!},
          }),
        '/api/vendors/profile' => json({'success': false, 'message': 'Vendor profile not found'}, 404),
        '/api/bookings/vendor' => json({'success': true, 'data': []}),
        _ => json({'success': false}, 404),
      };
    });

    final router = GoRouter(
      initialLocation: Routes.vendorHome,
      routes: [
        GoRoute(path: Routes.vendorHome, builder: (_, _) => const VendorDashboardScreen()),
        GoRoute(path: Routes.vendorBusiness, builder: (_, _) => const BusinessProfileScreen()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tokenStoreProvider.overrideWithValue(tokens),
          httpClientProvider.overrideWithValue(api),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Business opens an empty form for a vendor with no profile', (tester) async {
    // Roomy enough for the wide test font, with Quick actions on screen.
    tester.view.physicalSize = const Size(1800, 3600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpDashboard(tester);

    // Business comes first in Quick actions.
    expect(
      tester.getTopLeft(find.text('Business')).dx,
      lessThan(tester.getTopLeft(find.text('Services')).dx),
    );

    await tester.tap(find.text('Business'));
    await tester.pumpAndSettle();

    expect(find.text('Business profile'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(4));

    // Saving creates the profile, returns to the dashboard and clears the nudge.
    await tester.enterText(find.byType(TextFormField).at(0), 'Acme Events');
    await tester.enterText(find.byType(TextFormField).at(1), '1 Main St');
    await tester.enterText(find.byType(TextFormField).at(2), '+254700000000');
    await tester.enterText(find.byType(TextFormField).at(3), 'We plan great parties');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(created, {
      'business_name': 'Acme Events',
      'address': '1 Main St',
      'phone': '+254700000000',
      'description': 'We plan great parties',
    });
    expect(find.text('Finish setting up your business'), findsNothing);
    expect(find.text('Acme Events'), findsOneWidget);
  });
}
