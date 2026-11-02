import '../../../../core/error/failure.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/token_store.dart';
import '../../../../core/utils/json.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_mapper.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required LocalStorage storage,
    required TokenStore tokens,
    required bool isDemo,
  })  : _remote = remote,
        _storage = storage,
        _tokens = tokens,
        _isDemo = isDemo;

  final AuthRemoteDataSource _remote;
  final LocalStorage _storage;
  final TokenStore _tokens;
  final bool _isDemo;

  static String _normalise(String email) => email.trim().toLowerCase();

  @override
  AuthSession? restoreSession() {
    final access = _tokens.accessToken;
    final json = _storage.userJson;
    if (access == null || json == null) return null;
    return AuthSession(accessToken: access, refreshToken: _tokens.refreshToken, user: UserMapper.fromJson(json));
  }

  @override
  Future<AuthSession> login({required String email, required String password}) =>
      guard(() async => _persist(await _remote.login(_normalise(email), password)));

  @override
  Future<RegistrationResult> register({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
  }) =>
      guard(() async {
        final data = await _remote.register(
          fullName: fullName.trim(),
          email: _normalise(email),
          password: password,
          userType: role.name,
        );
        if (asBool(data['verification_required'])) {
          return VerificationRequired(asString(data['email'], _normalise(email)));
        }
        // Servers with verification disabled sign the user straight in.
        if (_accessTokenOf(data) != null) return RegistrationComplete(await _persist(data));
        return RegistrationComplete(await login(email: email, password: password));
      });

  @override
  Future<AuthSession> verifyEmail({required String email, required String code}) =>
      guard(() async => _persist(await _remote.verifyEmail(_normalise(email), code.trim())));

  @override
  Future<void> resendVerification(String email) => guard(() => _remote.resendVerification(_normalise(email)));

  @override
  Future<void> requestPasswordReset(String email) => guard(() => _remote.forgotPassword(_normalise(email)));

  @override
  Future<void> resetPassword({required String email, required String code, required String newPassword}) =>
      guard(() => _remote.resetPassword(_normalise(email), code.trim(), newPassword));

  static String? _accessTokenOf(Json data) => asStringOrNull(data['access_token'] ?? data['token']);

  Future<AuthSession> _persist(Json data) async {
    final access = _accessTokenOf(data);
    final userJson = asJson(data['user']);
    if (access == null || userJson.isEmpty) {
      throw const Failure('Sign-in failed. Please try again.');
    }
    final user = UserMapper.fromJson(userJson);
    final refresh = asStringOrNull(data['refresh_token']);
    await _tokens.save(accessToken: access, refreshToken: refresh);
    await _storage.saveSession(user: UserMapper.toJson(user), demo: _isDemo);
    return AuthSession(accessToken: access, refreshToken: refresh, user: user);
  }

  @override
  Future<void> cacheUser(User user) => _storage.saveUser(UserMapper.toJson(user));

  @override
  Future<void> logout() async {
    try {
      // Revoke server-side so a copied refresh token is useless.
      await _remote.logout(_tokens.refreshToken);
    } catch (_) {
      // Offline or already expired: still sign out locally.
    }
    await clearLocalSession();
  }

  @override
  Future<void> logoutEverywhere() async {
    await guard(_remote.logoutAll);
    await clearLocalSession();
  }

  @override
  Future<void> clearLocalSession() async {
    await _tokens.clear();
    await _storage.clearSession();
  }
}
