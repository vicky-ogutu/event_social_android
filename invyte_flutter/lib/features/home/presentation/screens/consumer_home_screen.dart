import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../../events/presentation/widgets/event_cards.dart';
import '../../../vendors/presentation/providers/vendor_providers.dart';
import '../../../vendors/presentation/widgets/vendor_cards.dart';

class ConsumerHomeScreen extends ConsumerWidget {
  const ConsumerHomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref
      ..invalidate(myEventsProvider)
      ..invalidate(discoverEventsProvider)
      ..invalidate(topVendorsProvider)
      ..invalidate(categoriesProvider);
    await ref.read(myEventsProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final upcoming = ref.watch(upcomingMyEventsProvider);
    final trending = ref.watch(discoverEventsProvider(const EventQuery()));
    final live = ref.watch(liveEventsProvider).value ?? const [];
    final vendors = ref.watch(topVendorsProvider);
    final categories = ref.watch(categoriesProvider);

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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_greeting()},',
                                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            Text('${user?.firstName ?? 'there'} 👋', style: theme.textTheme.headlineSmall),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go(Routes.profile),
                        child: UserAvatar(name: user?.fullName ?? '', url: user?.profilePicture, size: 48, ring: true),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _SearchBar(onTap: () => context.go(Routes.discover)),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 0), child: _PlanCard()),
            ),

            // ---- Categories ----
            SliverToBoxAdapter(
              child: categories.maybeWhen(
                data: (items) => SizedBox(
                  height: 108,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (_, i) => _CategoryBubble(
                      label: items[i].name,
                      icon: categoryIcon(items[i].name),
                      color: categoryColor(items[i].name),
                      onTap: () => context.go(Routes.discoverWith(category: items[i].name)),
                    ),
                  ),
                ),
                orElse: () => const SizedBox(height: 20),
              ),
            ),

            // ---- Live now ----
            if (live.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SectionHeader(title: 'Happening now 🔴')),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: live.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (_, i) => EventHeroCard(event: live[i], height: 200, width: 320),
                  ),
                ),
              ),
            ],

            // ---- My upcoming events ----
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Your upcoming events',
                actionLabel: 'See all',
                onAction: () => context.push(Routes.myEvents),
              ),
            ),
            SliverToBoxAdapter(
              child: upcoming.when(
                data: (events) => events.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Card(
                          child: EmptyState(
                            icon: Icons.event_available_rounded,
                            title: 'Nothing planned yet',
                            message: 'Create your first event and start inviting guests.',
                            actionLabel: 'Create event',
                            onAction: () => context.push(Routes.newEvent),
                            compact: true,
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          for (final e in events.take(3))
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                              child: EventListTile(event: e),
                            ),
                        ],
                      ),
                loading: () => const SkeletonList(count: 2, shrinkWrap: true),
                error: (e, _) => ErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(myEventsProvider),
                ),
              ),
            ),

            // ---- Top vendors ----
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Top-rated vendors',
                actionLabel: 'Explore',
                onAction: () => context.go(Routes.discover),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 212,
                child: vendors.when(
                  data: (items) => ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (_, i) => VendorCard(vendor: items[i]),
                  ),
                  loading: () => ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (_, _) => const Skeleton(width: 220, height: 212, radius: 20),
                  ),
                  error: (e, _) => Center(child: Text(e.toString())),
                ),
              ),
            ),

            // ---- Trending ----
            const SliverToBoxAdapter(child: SectionHeader(title: 'Trending near you')),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 230,
                child: trending.when(
                  data: (events) => ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: events.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (_, i) => EventHeroCard(event: events[i], height: 230),
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Skeleton(height: 230, radius: 20),
                  ),
                  error: (e, _) => Center(child: Text(e.toString())),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Search vendors, events, venues…',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ),
              const Icon(Icons.tune_rounded, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(Icons.celebration_rounded, size: 150, color: Colors.white.withValues(alpha: 0.12)),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Planning something special?',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  'Create an event, invite guests and book everything you need in one place.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), height: 1.4),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => context.push(Routes.newEvent),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(0, 46),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create event'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBubble extends StatelessWidget {
  const _CategoryBubble({required this.label, required this.icon, required this.color, required this.onTap});

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
