import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/widgets/common.dart';
import '../providers/vendor_providers.dart';

/// Vendors and stream organizers must finish Stripe's onboarding to get paid.
class PayoutsCard extends ConsumerStatefulWidget {
  const PayoutsCard({super.key});

  @override
  ConsumerState<PayoutsCard> createState() => _PayoutsCardState();
}

class _PayoutsCardState extends ConsumerState<PayoutsCard> {
  // Onboarding happens in the browser, so re-check on coming back.
  late final _lifecycle = AppLifecycleListener(onResume: () => ref.invalidate(payoutsReadyProvider));
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _lifecycle;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    setState(() => _opening = true);
    try {
      final url = await ref.read(vendorRepositoryProvider).startPayoutOnboarding();
      final opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!opened && mounted) showSnack(context, 'Could not open the payout setup page');
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = ref.watch(payoutsReadyProvider);
    final ready = status.value ?? false;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payouts', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              switch (status) {
                AsyncValue(hasValue: true) when ready => 'Payouts are active. Money you earn goes to your Stripe account.',
                AsyncValue(hasValue: true) => 'Set up payouts with Stripe to accept bookings and receive stream pass money.',
                AsyncValue(:final error?) => describeError(error),
                _ => 'Checking your payout status…',
              },
              style: theme.textTheme.bodySmall,
            ),
            if (status.hasValue && !ready) ...[
              const SizedBox(height: 14),
              PrimaryButton(label: 'Set up payouts', loading: _opening, onPressed: _open),
            ],
          ],
        ),
      ),
    );
  }
}
