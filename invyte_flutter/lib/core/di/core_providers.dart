import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../config/app_config.dart';
import '../demo/demo_backend.dart';
import '../network/api_client.dart';
import '../payments/payment_gateway.dart';
import '../realtime/realtime_service.dart';
import '../storage/local_storage.dart';
import '../storage/token_store.dart';

/// Composition root for app-wide infrastructure.

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Overridden in main()'),
);

final localStorageProvider = Provider<LocalStorage>(
  (ref) => LocalStorage(ref.watch(sharedPreferencesProvider)),
);

/// Session tokens in secure storage; opened in main() before the app starts.
final tokenStoreProvider = Provider<TokenStore>(
  (ref) => throw UnimplementedError('Overridden in main()'),
);

/// Whether the app talks to the in-memory [DemoBackend] instead of the API.
final demoModeProvider = NotifierProvider<DemoModeNotifier, bool>(DemoModeNotifier.new);

class DemoModeNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(localStorageProvider).isDemo;

  void set(bool value) => state = value;
}

/// Kept alive for the whole process so demo data survives navigation and
/// sign-out/sign-in within one launch.
final demoBackendProvider = Provider<DemoBackend>((ref) => DemoBackend());

final httpClientProvider = Provider<http.Client>((ref) {
  if (ref.watch(demoModeProvider)) return ref.watch(demoBackendProvider).client;
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    client: ref.watch(httpClientProvider),
    baseUrl: AppConfig.apiBaseUrl,
    tokens: ref.watch(tokenStoreProvider),
    onSessionExpired: () => ref.read(authControllerProvider.notifier).onSessionExpired(),
  );
});

/// Changes whenever the signed-in account changes. Feature repositories watch
/// it so every cached query is discarded on sign-out or account switch.
final sessionScopeProvider = Provider<Object?>((ref) {
  final auth = ref.watch(authControllerProvider);
  return (auth.user?.id, ref.watch(demoModeProvider));
});

final realtimeProvider = Provider<RealtimeService>((ref) {
  ref.watch(sessionScopeProvider);
  if (ref.watch(demoModeProvider)) return ref.watch(demoBackendProvider).realtime;
  final tokens = ref.watch(tokenStoreProvider);
  final service = SocketRealtimeService(
    url: AppConfig.socketUrl,
    // Read on every (re)connect so a refreshed access token is used.
    tokenReader: () => tokens.accessToken,
  )..connect();
  ref.onDispose(service.disconnect);
  return service;
});

/// Stripe PaymentSheet against the real API; instant success in demo mode.
final paymentGatewayProvider = Provider<PaymentGateway>((ref) {
  if (ref.watch(demoModeProvider)) return const DemoPaymentGateway();
  return StripePaymentGateway(ref.watch(apiClientProvider));
});

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.read(localStorageProvider).themeMode;

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(localStorageProvider).setThemeMode(mode);
  }
}
