import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../bookings/presentation/providers/booking_providers.dart';
import '../../../bookings/presentation/widgets/booking_actions.dart';
import '../../../bookings/presentation/widgets/booking_widgets.dart';
import '../../../events/presentation/widgets/join_with_code.dart';
import '../../../vendors/presentation/providers/vendor_providers.dart';

class VendorDashboardScreen extends ConsumerWidget {
  const VendorDashboardScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref
      ..invalidate(vendorBookingsProvider)
      ..invalidate(myVendorProfileProvider)
      ..invalidate(myServicesProvider);
    await ref.read(vendorBookingsProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(myVendorProfileProvider);
    final stats = ref.watch(vendorStatsProvider);
    final businessName = profile.value?.businessName ?? user?.businessName ?? user?.fullName ?? '';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: CustomScrollView(
          slivers: [
            SliverSafeArea(
              bottom: false,
              sliver: SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      UserAvatar(name: businessName, url: user?.profilePicture, size: 52, ring: true),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your studio',
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            Text(businessName,
                                maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleLarge),
                          ],
                        ),
                      ),
                      if (profile.value?.isApproved ?? false)
                        const StatusChip(label: 'Verified', color: AppColors.info, icon: Icons.verified_rounded),
                    ],
                  ),
                ),
              ),
            ),

            // Nudge new vendors to finish setup.
            if (profile.hasValue && profile.value == null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _SetupCard(onTap: () => context.push(Routes.vendorBusiness)),
                ),
              ),

            SliverToBoxAdapter(
              child: stats.when(
                data: (s) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    children: [
                      _RevenueCard(revenue: s.revenue, monthly: s.monthlyRevenue),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: StatTile(
                              label: 'New requests',
                              value: '${s.pending.length}',
                              icon: Icons.mark_email_unread_rounded,
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatTile(
                              label: 'Upcoming jobs',
                              value: '${s.upcoming.length}',
                              icon: Icons.event_available_rounded,
                              color: AppColors.info,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatTile(
                              label: 'Rating',
                              value: (profile.value?.rating ?? user?.rating ?? 0).toStringAsFixed(1),
                              icon: Icons.star_rounded,
                              color: AppColors.star,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Skeleton(height: 260, radius: 24),
                ),
                error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(vendorBookingsProvider)),
              ),
            ),

            // ---- Quick actions ----
            const SliverToBoxAdapter(child: SectionHeader(title: 'Quick actions')),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 104,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _QuickAction(
                      icon: Icons.storefront_rounded,
                      label: 'Business',
                      onTap: () => context.push(Routes.vendorBusiness),
                    ),
                    _QuickAction(
                      icon: Icons.design_services_rounded,
                      label: 'Services',
                      onTap: () => context.push(Routes.vendorServices),
                    ),
                    _QuickAction(
                      icon: Icons.photo_library_rounded,
                      label: 'Portfolio',
                      onTap: () => context.push(Routes.vendorPortfolio),
                    ),
                    _QuickAction(
                      icon: Icons.key_rounded,
                      label: 'Join event',
                      onTap: () => joinEventWithCode(context, ref),
                    ),
                    _QuickAction(
                      icon: Icons.chat_rounded,
                      label: 'Inbox',
                      onTap: () => context.go(Routes.vendorInbox),
                    ),
                  ],
                ),
              ),
            ),

            // ---- Requests ----
            ...stats.maybeWhen(
              data: (s) => [
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Needs your response',
                    actionLabel: s.pending.isEmpty ? null : 'View all',
                    onAction: () => context.go(Routes.vendorBookings),
                  ),
                ),
                if (s.pending.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Card(
                        child: EmptyState(
                          icon: Icons.inbox_rounded,
                          title: "You're all caught up",
                          message: 'New booking requests will appear here.',
                          compact: true,
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.separated(
                      itemCount: s.pending.take(3).length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => BookingCard(
                        booking: s.pending[i],
                        vendorView: true,
                        actions: VendorBookingActions(booking: s.pending[i]),
                      ),
                    ),
                  ),
                if (s.upcoming.isNotEmpty) ...[
                  const SliverToBoxAdapter(child: SectionHeader(title: 'Next up')),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.separated(
                      itemCount: s.upcoming.take(3).length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => BookingCard(booking: s.upcoming[i], vendorView: true),
                    ),
                  ),
                ],
              ],
              orElse: () => const <Widget>[],
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.revenue, required this.monthly});

  final double revenue;
  final List<(DateTime, double)> monthly;

  @override
  Widget build(BuildContext context) {
    final peak = monthly.fold<double>(0, (m, e) => e.$2 > m ? e.$2 : m);
    final thisMonth = monthly.isEmpty ? 0.0 : monthly.last.$2;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.nightGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Lifetime earnings', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text('This month ${Fmt.moneyCompact(thisMonth)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            Fmt.money(revenue),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (i, (month, value)) in monthly.indexed)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: peak == 0 ? 0.04 : (value / peak).clamp(0.04, 1.0)),
                            duration: Duration(milliseconds: 500 + i * 90),
                            curve: Curves.easeOutCubic,
                            builder: (_, t, _) => Container(
                              height: 80 * t,
                              decoration: BoxDecoration(
                                gradient: i == monthly.length - 1
                                    ? AppColors.brandGradient
                                    : LinearGradient(colors: [
                                        Colors.white.withValues(alpha: 0.35),
                                        Colors.white.withValues(alpha: 0.18),
                                      ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(DateFormat('MMM').format(month),
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: 92,
        child: Card(
          child: InkWell(
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.primary, size: 28),
                const SizedBox(height: 8),
                Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(Icons.rocket_launch_rounded, color: AppColors.primary, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Finish setting up your business', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text('Add your details and services to start receiving bookings.',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
