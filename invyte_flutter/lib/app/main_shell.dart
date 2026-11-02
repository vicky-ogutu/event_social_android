import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/di/core_providers.dart';
import '../core/theme/app_colors.dart';
import '../features/bookings/presentation/providers/booking_providers.dart';
import '../features/bookings/domain/entities/booking.dart';
import '../features/messaging/presentation/providers/message_providers.dart';

/// Bottom-navigation scaffold shared by the customer and vendor apps.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.shell, required this.vendor});

  final StatefulNavigationShell shell;
  final bool vendor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    final pendingRequests = vendor
        ? (ref.watch(vendorBookingsProvider).value ?? const [])
            .where((b) => b.status == BookingStatus.pending)
            .length
        : 0;
    final isDemo = ref.watch(demoModeProvider);

    final destinations = [
      vendor
          ? const NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard_rounded),
              label: 'Studio',
            )
          : const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
      vendor
          ? NavigationDestination(
              icon: _badge(const Icon(Icons.event_note_outlined), pendingRequests),
              selectedIcon: _badge(const Icon(Icons.event_note_rounded), pendingRequests),
              label: 'Bookings',
            )
          : const NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore_rounded),
              label: 'Discover',
            ),
      const NavigationDestination(
        icon: Icon(Icons.dynamic_feed_outlined),
        selectedIcon: Icon(Icons.dynamic_feed_rounded),
        label: 'Moments',
      ),
      NavigationDestination(
        icon: _badge(const Icon(Icons.chat_bubble_outline_rounded), unread),
        selectedIcon: _badge(const Icon(Icons.chat_bubble_rounded), unread),
        label: 'Inbox',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline_rounded),
        selectedIcon: Icon(Icons.person_rounded),
        label: 'Profile',
      ),
    ];

    return Scaffold(
      body: Column(
        children: [
          if (isDemo) const _DemoBanner(),
          // The banner already consumed the status-bar inset.
          Expanded(
            child: MediaQuery.removePadding(context: context, removeTop: isDemo, child: shell),
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline)),
        ),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          destinations: destinations,
          onDestinationSelected: (index) => shell.goBranch(index, initialLocation: index == shell.currentIndex),
        ),
      ),
    );
  }

  static Widget _badge(Widget icon, int count) =>
      count == 0 ? icon : Badge(label: Text(count > 9 ? '9+' : '$count'), child: icon);
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                'Demo mode · sample data',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
