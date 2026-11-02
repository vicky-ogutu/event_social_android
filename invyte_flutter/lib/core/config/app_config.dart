/// Compile-time configuration.
///
/// Override at build time, e.g.
/// `flutter run --dart-define=API_BASE_URL=https://api.invyte.app`
abstract final class AppConfig {
  static const appName = 'Invyte';
  static const tagline = 'Plan it. Book it. Live it.';

  /// REST API origin (no trailing slash). `10.0.2.2` is the host machine as
  /// seen from the Android emulator.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.100.24:3000',
  );
  //defaultValue: 'http://10.0.2.2:3000',

  /// Socket.IO origin used for real-time chat.
  static const socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: apiBaseUrl,
  );

  static const currencySymbol = String.fromEnvironment(
    'CURRENCY_SYMBOL',
    defaultValue: r'$',
  );

  /// Used only to show estimates before the server prices a booking.
  static const estimatedServiceFeeRate = 0.05;

  static const requestTimeout = Duration(seconds: 20);

  /// Optional: Stripe publishable key. When empty the app fetches it from
  /// `GET /api/payments/config`, so keys live only on the server.
  static const stripePublishableKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');

  /// Apple Pay merchant id (iOS only); leave empty to disable Apple Pay.
  static const appleMerchantId = String.fromEnvironment('APPLE_MERCHANT_ID');
}
