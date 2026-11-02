import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invyte/core/storage/token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('moves a token left in plain preferences into secure storage', () async {
    SharedPreferences.setMockInitialValues({'session.token': 'legacy-token'});
    FlutterSecureStorage.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final store = await TokenStore.open(prefs);

    expect(store.accessToken, 'legacy-token');
    expect(prefs.getString('session.token'), isNull, reason: 'plain-text copy is erased');
    expect(await const FlutterSecureStorage().read(key: 'auth.access_token'), 'legacy-token');
  });

  test('persists across launches and clears completely', () async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final first = await TokenStore.open(prefs);
    await first.save(accessToken: 'a', refreshToken: 'r');

    final second = await TokenStore.open(prefs);
    expect([second.accessToken, second.refreshToken], ['a', 'r']);
    expect(prefs.getKeys().any((k) => prefs.get(k).toString().contains('a')), isFalse,
        reason: 'tokens never touch shared_preferences');

    await second.clear();
    final third = await TokenStore.open(prefs);
    expect(third.hasSession, isFalse);
    expect(third.refreshToken, isNull);
  });
}
