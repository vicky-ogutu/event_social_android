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
import 'package:invyte/features/events/presentation/providers/event_providers.dart';
import 'package:invyte/features/events/presentation/screens/event_detail_screen.dart';
import 'package:invyte/features/events/presentation/widgets/join_with_code.dart';
import 'package:invyte/features/home/presentation/screens/consumer_home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A guest with only an access code joins a private event and lands on it,
/// against a fake of the real API.
void main() {
  const event = {
    'id': 7,
    'uuid': 'e7',
    'organizer_id': 99,
    'event_name': 'Secret Party',
    'event_type': 'private',
    'event_date': '2030-01-01',
    'start_time': '18:00:00',
  };

  late List<String> submitted;
  late int myEventsRequests;

  http.Response json(Object body, [int status = 200]) =>
      http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});

  Future<void> pumpHome(WidgetTester tester, {Widget? home, bool openDialog = true}) async {
    tester.view.physicalSize = const Size(1800, 3600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({'app.onboarded': true});
    FlutterSecureStorage.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final tokens = await TokenStore.open(prefs);
    submitted = [];
    myEventsRequests = 0;

    final api = MockClient((request) async {
      final path = request.url.path;
      if (path == '/api/events/join') {
        final code = (jsonDecode(request.body) as Map)['access_code'] as String;
        submitted.add(code);
        if (code == 'SLOW4321') return json({'success': false, 'code': 'RATE_LIMITED', 'message': 'Too many incorrect codes.'}, 429);
        if (code != 'PARTY2030') return json({'success': false, 'message': 'Invalid access code'}, 403);
        return json({'success': true, 'data': event});
      }
      if (path == '/api/events/my-events') myEventsRequests++;
      if (path == '/api/events/7') return json({'success': true, 'data': event});
      return json({'success': true, 'data': []});
    });

    final router = GoRouter(
      initialLocation: Routes.home,
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (_, _) => home ?? Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                ref.watch(_myEventsWatcher);
                return Center(
                  child: TextButton(
                    onPressed: () => joinEventWithCode(context, ref),
                    child: const Text('Open join'),
                  ),
                );
              },
            ),
          ),
        ),
        GoRoute(path: '/events/:id', builder: (_, s) => EventDetailScreen(eventId: int.parse(s.pathParameters['id']!))),
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
    if (openDialog) {
      await tester.tap(find.text('Open join'));
      await tester.pumpAndSettle();
    }
  }

  Future<void> submit(WidgetTester tester, String code) async {
    await tester.enterText(find.byType(TextFormField), code);
    await tester.tap(find.widgetWithText(FilledButton, 'Join'));
    await tester.pumpAndSettle();
  }

  testWidgets('a correct code in any case opens the event with no join bar', (tester) async {
    await pumpHome(tester);

    await submit(tester, '  party2030 ');

    expect(submitted, ['PARTY2030']);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Secret Party'), findsWidgets);
    expect(find.text('Join event'), findsNothing);
    expect(find.text('Join with code'), findsNothing);
  });

  testWidgets('a wrong code keeps the dialog open and shows why', (tester) async {
    await pumpHome(tester);

    await submit(tester, 'WRONG999');

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Invalid access code'), findsOneWidget);

    await submit(tester, 'PARTY2030');
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Secret Party'), findsWidgets);
  });

  testWidgets('the rate limit message reaches the guest', (tester) async {
    await pumpHome(tester);
    await submit(tester, 'SLOW4321');
    expect(find.text('Too many incorrect codes.'), findsOneWidget);
  });

  testWidgets('an empty code is not sent', (tester) async {
    await pumpHome(tester);
    await submit(tester, '   ');
    expect(submitted, isEmpty);
    expect(find.text('Access code is required'), findsOneWidget);
  });

  testWidgets('the home screen offers Join with code', (tester) async {
    await pumpHome(tester, home: const ConsumerHomeScreen(), openDialog: false);

    await tester.tap(find.text('Join with code'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await submit(tester, 'PARTY2030');
    expect(find.text('Secret Party'), findsWidgets);
  });

  testWidgets('joining refreshes My Events', (tester) async {
    await pumpHome(tester);
    final before = myEventsRequests;

    await submit(tester, 'PARTY2030');

    expect(before, 1);
    expect(myEventsRequests, greaterThan(before));
  });
}

final _myEventsWatcher = Provider<void>((ref) {
  ref.watch(_loadMyEvents);
});

final _loadMyEvents = FutureProvider<void>((ref) async {
  await ref.watch(myEventsProvider.future);
});
