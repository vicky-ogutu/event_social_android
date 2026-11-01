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
import 'package:invyte/features/home/presentation/screens/discover_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Category links from the home tab must keep working after the filter is
/// changed on Discover, which stays alive in its own shell branch.
void main() {
  http.Response json(Object body) =>
      http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json; charset=utf-8'});

  Future<void> pumpApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'app.onboarded': true});
    FlutterSecureStorage.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final tokens = await TokenStore.open(prefs);

    final api = MockClient((request) async {
      return switch (request.url.path) {
        '/api/vendors/categories' => json({
            'success': true,
            'data': [
              {'id': 2, 'name': 'Catering', 'slug': 'catering'},
            ],
          }),
        _ => json({'success': true, 'data': []}),
      };
    });

    final router = GoRouter(
      initialLocation: Routes.home,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => Scaffold(
            body: shell,
            bottomNavigationBar: TextButton(onPressed: () => shell.goBranch(0), child: const Text('Home tab')),
          ),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                path: Routes.home,
                builder: (context, _) => Center(
                  child: TextButton(
                    onPressed: () => context.go(Routes.discoverWith(category: 'Catering')),
                    child: const Text('Home catering'),
                  ),
                ),
              ),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                path: Routes.discover,
                builder: (_, s) => DiscoverScreen(initialCategory: s.uri.queryParameters['category']),
              ),
            ]),
          ],
        ),
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

  bool selected(WidgetTester tester, String chip) =>
      tester.widget<FilterChip>(find.widgetWithText(FilterChip, chip)).selected;

  testWidgets('home category applies again after choosing All on Discover', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Home catering'));
    await tester.pumpAndSettle();
    expect(selected(tester, 'Catering'), isTrue);

    await tester.tap(find.widgetWithText(FilterChip, 'All'));
    await tester.pumpAndSettle();
    expect(selected(tester, 'All'), isTrue);

    await tester.tap(find.text('Home tab'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home catering'));
    await tester.pumpAndSettle();

    expect(selected(tester, 'Catering'), isTrue);
    expect(selected(tester, 'All'), isFalse);
  });

  testWidgets('home category applies again after unselecting its chip', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Home catering'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'Catering'));
    await tester.pumpAndSettle();
    expect(selected(tester, 'All'), isTrue);

    await tester.tap(find.text('Home tab'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home catering'));
    await tester.pumpAndSettle();

    expect(selected(tester, 'Catering'), isTrue);
  });
}
