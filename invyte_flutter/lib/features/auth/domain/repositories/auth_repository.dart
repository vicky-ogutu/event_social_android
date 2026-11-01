import '../entities/user.dart';

abstract interface class AuthRepository {
  /// Returns the session persisted from a previous launch, if any.
  AuthSession? restoreSession();

  Future<AuthSession> login({required String email, required String password});

  Future<RegistrationResult> register({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
  });

  /// Confirms the 6-digit code emailed at sign-up and signs the user in.
  Future<AuthSession> verifyEmail({required String email, required String code});

  Future<void> resendVerification(String email);

  /// Emails a 6-digit reset code (the response never reveals if the account exists).
  Future<void> requestPasswordReset(String email);

  Future<void> resetPassword({required String email, required String code, required String newPassword});

  /// Persists an updated profile so it survives restarts.
  Future<void> cacheUser(User user);

  /// Ends this device's session on the server and locally.
  Future<void> logout();

  /// Ends every session for the account, on all devices.
  Future<void> logoutEverywhere();

  /// Clears local credentials only (server already rejected them).
  Future<void> clearLocalSession();
}
