import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:invyte/core/error/failure.dart';
import 'package:invyte/core/network/api_client.dart';
import 'package:invyte/core/storage/token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late TokenStore tokens;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    tokens = await TokenStore.open(await SharedPreferences.getInstance());
    await tokens.save(accessToken: 'access-1', refreshToken: 'refresh-1');
  });

  ApiClient clientWith(MockClientHandler handler, {void Function()? onSessionExpired}) => ApiClient(
        client: MockClient(handler),
        baseUrl: 'https://api.test/',
        tokens: tokens,
        onSessionExpired: onSessionExpired,
      );

  http.Response json(Object body, [int status = 200]) => http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  test('unwraps the success envelope and sends auth + query params', () async {
    late http.Request captured;
    final api = clientWith((request) async {
      captured = request;
      return json({'success': true, 'message': 'ok', 'data': {'id': 7}});
    });

    final data = await api.get('api/events', query: {'page': 2, 'search': null});

    expect(data, {'id': 7});
    expect(captured.url.toString(), 'https://api.test/api/events?page=2');
    expect(captured.headers['Authorization'], 'Bearer access-1');
  });

  test('maps server errors to a Failure with status and code', () async {
    final api = clientWith((_) async => json({'success': false, 'code': 'NOPE', 'message': 'Event not found'}, 404));

    expect(
      () => api.get('api/events/1'),
      throwsA(isA<Failure>()
          .having((f) => f.message, 'message', 'Event not found')
          .having((f) => f.code, 'code', 'NOPE')
          .having((f) => f.isNotFound, 'isNotFound', true)),
    );
  });

  test('treats success:false on a 200 as a failure', () async {
    final api = clientWith((_) async => json({'success': false, 'message': 'Nope'}));
    expect(() => api.post('api/x'), throwsA(isA<Failure>().having((f) => f.message, 'message', 'Nope')));
  });

  test('converts transport errors into a NetworkFailure', () async {
    final api = clientWith((_) async => throw http.ClientException('offline'));
    expect(() => api.get('api/events'), throwsA(isA<NetworkFailure>()));
  });

  group('token refresh', () {
    test('renews an expired access token once and retries the request', () async {
      final calls = <String>[];
      final api = clientWith((request) async {
        calls.add('${request.url.path} ${request.headers['Authorization'] ?? ''}');
        if (request.url.path == '/api/auth/refresh') {
          expect(jsonDecode(request.body)['refresh_token'], 'refresh-1');
          return json({'success': true, 'data': {'access_token': 'access-2', 'refresh_token': 'refresh-2'}});
        }
        return request.headers['Authorization'] == 'Bearer access-2'
            ? json({'success': true, 'data': 'ok'})
            : json({'success': false, 'message': 'expired'}, 401);
      });

      expect(await api.get('api/bookings'), 'ok');
      expect(calls, ['/api/bookings Bearer access-1', '/api/auth/refresh ', '/api/bookings Bearer access-2']);
      expect(tokens.accessToken, 'access-2');
      expect(tokens.refreshToken, 'refresh-2', reason: 'rotated refresh token is stored');
    });

    test('concurrent 401s share a single refresh (the token is single-use)', () async {
      var refreshes = 0;
      final api = clientWith((request) async {
        if (request.url.path == '/api/auth/refresh') {
          refreshes++;
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return json({'success': true, 'data': {'access_token': 'access-2', 'refresh_token': 'refresh-2'}});
        }
        return request.headers['Authorization'] == 'Bearer access-2'
            ? json({'success': true, 'data': request.url.path})
            : json({'success': false}, 401);
      });

      final results = await Future.wait([api.get('api/a'), api.get('api/b'), api.get('api/c')]);
      expect(results, ['/api/a', '/api/b', '/api/c']);
      expect(refreshes, 1);
    });

    test('a rejected refresh ends the session', () async {
      var expired = 0;
      final api = clientWith(
        (request) async => request.url.path == '/api/auth/refresh'
            ? json({'success': false, 'code': 'SESSION_EXPIRED', 'message': 'Session expired'}, 401)
            : json({'success': false, 'message': 'expired'}, 401),
        onSessionExpired: () => expired++,
      );

      await expectLater(api.get('api/bookings'), throwsA(isA<Failure>()));
      expect(expired, 1);
    });

    test('being offline during refresh does not sign the user out', () async {
      var expired = 0;
      final api = clientWith(
        (request) async => request.url.path == '/api/auth/refresh'
            ? throw http.ClientException('offline')
            : json({'success': false}, 401),
        onSessionExpired: () => expired++,
      );

      await expectLater(api.get('api/bookings'), throwsA(isA<NetworkFailure>()));
      expect(expired, 0);
      expect(tokens.refreshToken, 'refresh-1');
    });

    test('wrong password on login is not mistaken for an expired session', () async {
      var refreshed = false;
      var expired = 0;
      final api = clientWith((request) async {
        if (request.url.path == '/api/auth/refresh') refreshed = true;
        return json({'success': false, 'code': 'INVALID_CREDENTIALS', 'message': 'Invalid email or password.'}, 401);
      }, onSessionExpired: () => expired++);

      await expectLater(
        api.post('api/auth/login', body: {'email': 'a@b.c', 'password': 'x'}),
        throwsA(isA<Failure>().having((f) => f.code, 'code', 'INVALID_CREDENTIALS')),
      );
      expect(refreshed, isFalse);
      expect(expired, 0);
    });
  });
}
