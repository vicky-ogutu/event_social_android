import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._api);

  final ApiClient _api;

  Future<Json> login(String email, String password) async =>
      asJson(await _api.post('api/auth/login', body: {'email': email, 'password': password}));

  Future<Json> register({
    required String fullName,
    required String email,
    required String password,
    required String userType,
  }) async =>
      asJson(await _api.post('api/auth/register', body: {
        'full_name': fullName,
        'email': email,
        'password': password,
        'user_type': userType,
      }));

  Future<Json> verifyEmail(String email, String code) async =>
      asJson(await _api.post('api/auth/verify-email', body: {'email': email, 'code': code}));

  Future<void> resendVerification(String email) =>
      _api.post('api/auth/resend-verification', body: {'email': email});

  Future<void> forgotPassword(String email) => _api.post('api/auth/forgot-password', body: {'email': email});

  Future<void> resetPassword(String email, String code, String newPassword) => _api.post(
        'api/auth/reset-password',
        body: {'email': email, 'code': code, 'new_password': newPassword},
      );

  Future<void> logout(String? refreshToken) =>
      _api.post('api/auth/logout', body: {'refresh_token': refreshToken});

  Future<void> logoutAll() => _api.post('api/auth/logout-all');
}
