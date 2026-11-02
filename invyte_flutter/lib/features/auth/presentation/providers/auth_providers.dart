import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/demo/demo_seed.dart';
import '../../../../core/di/core_providers.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepositoryImpl(
      remote: AuthRemoteDataSource(ref.watch(apiClientProvider)),
      storage: ref.watch(localStorageProvider),
      tokens: ref.watch(tokenStoreProvider),
      isDemo: ref.watch(demoModeProvider),
    ));

class AuthState {
  const AuthState._(this.user, {this.sessionExpired = false});

  const AuthState.signedOut({bool sessionExpired = false}) : this._(null, sessionExpired: sessionExpired);

  const AuthState.signedIn(User user) : this._(user);

  final User? user;

  /// True when the server rejected our token (vs. a deliberate sign-out).
  final bool sessionExpired;

  bool get isAuthenticated => user != null;
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

/// Convenience accessor; most screens only need the user.
final currentUserProvider = Provider<User?>((ref) => ref.watch(authControllerProvider).user);

class AuthController extends Notifier<AuthState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    final session = ref.read(authRepositoryProvider).restoreSession();
    return session == null ? const AuthState.signedOut() : AuthState.signedIn(session.user);
  }

  Future<void> login(String email, String password) async {
    ref.read(demoModeProvider.notifier).set(false);
    final session = await _repository.login(email: email, password: password);
    state = AuthState.signedIn(session.user);
  }

  /// Returns the email that must be verified, or `null` if already signed in.
  Future<String?> register({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    ref.read(demoModeProvider.notifier).set(false);
    final result = await _repository.register(
      fullName: fullName,
      email: email,
      password: password,
      role: role,
    );
    switch (result) {
      case RegistrationComplete(:final session):
        state = AuthState.signedIn(session.user);
        return null;
      case VerificationRequired(:final email):
        return email;
    }
  }

  Future<void> verifyEmail({required String email, required String code}) async {
    ref.read(demoModeProvider.notifier).set(false);
    final session = await _repository.verifyEmail(email: email, code: code);
    state = AuthState.signedIn(session.user);
  }

  /// Signs into the in-memory demo backend with a pre-seeded account.
  Future<void> startDemo(UserRole role) async {
    ref.read(demoModeProvider.notifier).set(true);
    try {
      final session = await _repository.login(
        email: role == UserRole.vendor ? DemoSeed.vendorEmail : DemoSeed.consumerEmail,
        password: DemoSeed.password,
      );
      state = AuthState.signedIn(session.user);
    } catch (_) {
      ref.read(demoModeProvider.notifier).set(false);
      rethrow;
    }
  }

  Future<void> updateUser(User user) async {
    await _repository.cacheUser(user);
    state = AuthState.signedIn(user);
  }

  Future<void> logout() async {
    await _repository.logout();
    ref.read(demoModeProvider.notifier).set(false);
    state = const AuthState.signedOut();
  }

  /// Signs out on every device (e.g. after losing a phone).
  Future<void> logoutEverywhere() async {
    await _repository.logoutEverywhere();
    ref.read(demoModeProvider.notifier).set(false);
    state = const AuthState.signedOut();
  }

  /// Called by the HTTP layer when the refresh token was rejected.
  void onSessionExpired() {
    if (!state.isAuthenticated) return;
    _repository.clearLocalSession();
    state = const AuthState.signedOut(sessionExpired: true);
  }
}
