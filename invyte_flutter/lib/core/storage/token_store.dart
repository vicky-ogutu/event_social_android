import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Session credentials, kept in the platform keystore (iOS Keychain /
/// Android Keystore-backed storage) rather than plain preferences.
///
/// Values are cached in memory after [open] so the HTTP layer can read the
/// access token synchronously on every request.
class TokenStore {
  TokenStore._(this._secure, this._accessToken, this._refreshToken);

  static const _kAccess = 'auth.access_token';
  static const _kRefresh = 'auth.refresh_token';

  /// Where tokens lived before secure storage; migrated on first launch.
  static const _legacyPrefsKey = 'session.token';

  static const _storage = FlutterSecureStorage(
    // Readable after first unlock (background refresh), never synced to
    // other devices or included in iCloud backups.
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  final FlutterSecureStorage _secure;
  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get hasSession => _accessToken != null;

  static Future<TokenStore> open(SharedPreferences prefs, {FlutterSecureStorage storage = _storage}) async {
    var access = await _read(storage, _kAccess);
    final refresh = await _read(storage, _kRefresh);

    final legacy = prefs.getString(_legacyPrefsKey);
    if (legacy != null) {
      // Move the old plain-text token into the keystore, then erase it.
      if (access == null) {
        await storage.write(key: _kAccess, value: legacy);
        access = legacy;
      }
      await prefs.remove(_legacyPrefsKey);
    }
    return TokenStore._(storage, access, refresh);
  }

  /// A corrupted keystore entry (e.g. after a device restore) is treated as
  /// "signed out" rather than crashing startup.
  static Future<String?> _read(FlutterSecureStorage storage, String key) async {
    try {
      return await storage.read(key: key);
    } catch (_) {
      await storage.delete(key: key).catchError((_) {});
      return null;
    }
  }

  Future<void> save({required String accessToken, String? refreshToken}) async {
    _accessToken = accessToken;
    if (refreshToken != null) _refreshToken = refreshToken;
    await _secure.write(key: _kAccess, value: accessToken);
    if (refreshToken != null) await _secure.write(key: _kRefresh, value: refreshToken);
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    await _secure.delete(key: _kAccess);
    await _secure.delete(key: _kRefresh);
  }
}
