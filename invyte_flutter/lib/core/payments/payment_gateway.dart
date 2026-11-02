import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../config/app_config.dart';
import '../error/failure.dart';
import '../network/api_client.dart';
import '../theme/app_colors.dart';
import '../utils/json.dart';

enum PaymentOutcome { succeeded, cancelled }

/// Collects a payment for a server-created PaymentIntent.
abstract interface class PaymentGateway {
  Future<PaymentOutcome> collect({required String clientSecret});
}

/// Presents Stripe's PaymentSheet (cards, Google Pay, Apple Pay).
class StripePaymentGateway implements PaymentGateway {
  StripePaymentGateway(this._api);

  final ApiClient _api;
  String _merchantName = 'Invyte';
  bool _configured = false;
  bool _testMode = true;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    var key = AppConfig.stripePublishableKey;
    if (key.isEmpty) {
      final config = asJson(await _api.get('api/payments/config'));
      key = asString(config['publishableKey'] ?? config['publishable_key']);
      _merchantName = asString(config['merchantDisplayName'], _merchantName);
    }
    if (key.isEmpty) throw const Failure('Payments are not configured yet.');
    Stripe.publishableKey = key;
    _testMode = key.startsWith('pk_test_');
    if (AppConfig.appleMerchantId.isNotEmpty) Stripe.merchantIdentifier = AppConfig.appleMerchantId;
    await Stripe.instance.applySettings();
    _configured = true;
  }

  @override
  Future<PaymentOutcome> collect({required String clientSecret}) async {
    await _ensureConfigured();
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: _merchantName,
          style: ThemeMode.system,
          googlePay: PaymentSheetGooglePay(merchantCountryCode: 'US', testEnv: _testMode),
          applePay: AppConfig.appleMerchantId.isEmpty
              ? null
              : const PaymentSheetApplePay(merchantCountryCode: 'US'),
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(primary: AppColors.primary),
            shapes: PaymentSheetShape(borderRadius: 14),
          ),
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      return PaymentOutcome.succeeded;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) return PaymentOutcome.cancelled;
      throw Failure(e.error.localizedMessage ?? e.error.message ?? 'Payment failed. Please try another card.');
    }
  }
}

/// Demo mode: the in-memory backend settles payments itself.
class DemoPaymentGateway implements PaymentGateway {
  const DemoPaymentGateway();

  @override
  Future<PaymentOutcome> collect({required String clientSecret}) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return PaymentOutcome.succeeded;
  }
}
