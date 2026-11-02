import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:invyte/core/di/core_providers.dart';
import 'package:invyte/core/storage/token_store.dart';
import 'package:invyte/features/auth/domain/entities/user.dart';
import 'package:invyte/features/auth/presentation/providers/auth_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sign-up → email code → signed in, and logout revoking server-side,
/// against a fake of the real (non-demo) API.
void main() {
  late ProviderContainer container;
  late TokenStore tokens;
  late SharedPreferences prefs;
  final requests = <String, Map<String, dynamic>>{};

  http.Response json(Object body, [int status = 200]) =>
      http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'});

  final user = {'id': 5, 'uuid': 'u5', 'email': 'new@invyte.app', 'full_name': 'New Person', 'user_type': 'consumer'};

  setUp(() async {
    SharedPreferences.setMockInitialValues({'app.onboarded': true});
    FlutterSecureStorage.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    tokens = await TokenStore.open(prefs);
    requests.clear();

    final api = MockClient((request) async {
      final body = request.body.isEmpty ? <String, dynamic>{} : jsonDecode(request.body) as Map<String, dynamic>;
      requests[request.url.path] = body;
      return switch (request.url.path) {
        '/api/auth/register' => json({
            'success': true,
            'data': {'verification_required': true, 'email': 'new@invyte.app'},
          }, 201),
        '/api/auth/verify-email' when body['code'] == '123456' => json({
            'success': true,
            'data': {'access_token': 'acc', 'refresh_token': 'ref', 'user': user},
          }),
        '/api/auth/verify-email' => json({'success': false, 'code': 'INVALID_CODE', 'message': 'Invalid code'}, 400),
        '/api/auth/logout' => json({'success': true}),
        _ => json({'success': false}, 404),
      };
    });

    container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      tokenStoreProvider.overrideWithValue(tokens),
      httpClientProvider.overrideWithValue(api),
    ]);
  });

  tearDown(() => container.dispose());

  test('sign-up requires the emailed code before signing in', () async {
    final auth = container.read(authControllerProvider.notifier);

    final pending = await auth.register(
      fullName: 'New Person',
      email: ' New@Invyte.app ',
      password: 'Password123',
      role: UserRole.consumer,
    );
    expect(pending, 'new@invyte.app');
    expect(container.read(currentUserProvider), isNull);
    expect(tokens.hasSession, isFalse);

    await expectLater(auth.verifyEmail(email: pending!, code: '000000'), throwsA(isA<Exception>()));
    expect(container.read(currentUserProvider), isNull);

    await auth.verifyEmail(email: pending, code: '123456');
    expect(container.read(currentUserProvider)?.email, 'new@invyte.app');
    expect([tokens.accessToken, tokens.refreshToken], ['acc', 'ref']);
    expect(prefs.getKeys().where((k) => prefs.get(k).toString().contains('acc')), isEmpty,
        reason: 'tokens are only in secure storage');
  });

  test('logout revokes the refresh token on the server and clears the device', () async {
    final auth = container.read(authControllerProvider.notifier);
    await auth.verifyEmail(email: 'new@invyte.app', code: '123456');

    await auth.logout();

    expect(requests['/api/auth/logout'], {'refresh_token': 'ref'});
    expect(container.read(currentUserProvider), isNull);
    expect(tokens.hasSession, isFalse);
    expect(prefs.getString('session.user'), isNull);
  });
}
