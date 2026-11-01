import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/payments/payment_gateway.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/booking.dart';
import '../providers/booking_providers.dart';
import '../widgets/booking_widgets.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, required this.bookingId});

  final int bookingId;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _paying = false;
  bool _done = false;

  Future<void> _pay() async {
    setState(() => _paying = true);
    try {
      final bookings = ref.read(bookingRepositoryProvider);
      final intent = await bookings.createPaymentIntent(widget.bookingId);
      final outcome = await ref.read(paymentGatewayProvider).collect(clientSecret: intent.clientSecret);
      if (outcome == PaymentOutcome.cancelled) return;
      await bookings.confirmPayment(intent.id);
      invalidateBookings(ref, bookingId: widget.bookingId);
      if (mounted) setState(() => _done = true);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = ref.watch(bookingDetailProvider(widget.bookingId));
    if (_done) return _SuccessView(bookingId: widget.bookingId);
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: AsyncValueView(
        value: booking,
        onRetry: () => ref.invalidate(bookingDetailProvider(widget.bookingId)),
        data: (Booking b) => Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  Panel(
                    title: 'Order summary',
                    child: Column(
                      children: [
                        InfoRow(
                          icon: Icons.design_services_rounded,
                          title: b.serviceName ?? 'Service',
                          subtitle: b.vendorName,
                        ),
                        InfoRow(
                          icon: Icons.event_rounded,
                          title: b.eventName ?? 'Event',
                          subtitle: '${Fmt.date(b.serviceDate)} · ${Fmt.time(b.serviceTime)}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Panel(
                    title: 'Payment method',
                    child: _CardPreview(demo: ref.watch(demoModeProvider)),
                  ),
                  const SizedBox(height: 16),
                  Panel(
                    title: 'Price details',
                    child: PriceBreakdown(
                      subtotal: b.agreedPrice,
                      serviceFee: b.serviceFee,
                      tax: b.taxAmount,
                      total: b.totalAmount,
                      paid: b.amountPaid,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _TrustRow(),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: b.isPaid
                    ? OutlinedButton(
                        onPressed: () => context.pushReplacement(Routes.booking(b.id)),
                        child: const Text('Already paid · View booking'),
                      )
                    : PrimaryButton(
                        label: 'Pay ${Fmt.money(b.balanceDue)}',
                        icon: Icons.lock_rounded,
                        loading: _paying,
                        onPressed: _pay,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardPreview extends StatelessWidget {
  const _CardPreview({required this.demo});

  final bool demo;

  @override
  Widget build(BuildContext context) {
    if (!demo) return const _PaymentMethods();
    return Container(
      height: 170,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: AppColors.nightGradient, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.contactless_rounded, color: Colors.white70),
              Spacer(),
              Text('DEMO', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800, letterSpacing: 2)),
            ],
          ),
          const Spacer(),
          const Text('••••  ••••  ••••  4242',
              style: TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 2, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Secured by Stripe', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
              const Spacer(),
              const Text('12/29', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Live mode: the actual method is chosen in Stripe's payment sheet.
class _PaymentMethods extends StatelessWidget {
  const _PaymentMethods();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget method(IconData icon, String label) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(height: 6),
                Text(label, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            method(Icons.credit_card_rounded, 'Card'),
            const SizedBox(width: 10),
            method(Icons.account_balance_wallet_rounded, 'Google Pay'),
            const SizedBox(width: 10),
            method(Icons.phone_iphone_rounded, 'Apple Pay'),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          "You'll choose how to pay in Stripe's secure checkout. Invyte never sees your card details.",
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    Widget item(IconData icon, String label) => Expanded(
          child: Column(
            children: [
              Icon(icon, color: AppColors.success),
              const SizedBox(height: 6),
              Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: muted)),
            ],
          ),
        );
    return Row(
      children: [
        item(Icons.lock_rounded, 'Encrypted\npayments'),
        item(Icons.account_balance_wallet_rounded, 'Held until\ndelivery'),
        item(Icons.support_agent_rounded, '24/7\nsupport'),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.bookingId});

  final int bookingId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                builder: (_, t, child) => Transform.scale(scale: t, child: child),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.brandGradient),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 64),
                ),
              ),
              const SizedBox(height: 32),
              Text('Payment complete!', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 10),
              Text(
                "Your booking is secured. We'll notify you as soon as the vendor confirms.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'View booking',
                onPressed: () => context.pushReplacement(Routes.booking(bookingId)),
              ),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: () => context.go(Routes.home), child: const Text('Back to home')),
            ],
          ),
        ),
      ),
    );
  }
}
