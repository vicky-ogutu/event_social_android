import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/vendor.dart';
import '../providers/vendor_providers.dart';
import '../widgets/vendor_cards.dart';

class VendorDetailScreen extends ConsumerWidget {
  const VendorDetailScreen({super.key, required this.vendorId});

  final int vendorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendor = ref.watch(vendorDetailProvider(vendorId));
    return Scaffold(
      body: AsyncValueView(
        value: vendor,
        onRetry: () => ref.invalidate(vendorDetailProvider(vendorId)),
        loading: const Center(child: CircularProgressIndicator()),
        data: (Vendor v) => _VendorBody(vendor: v),
      ),
    );
  }
}

class _VendorBody extends ConsumerWidget {
  const _VendorBody({required this.vendor});

  final Vendor vendor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final me = ref.watch(currentUserProvider);
    final canBook = !(me?.isVendor ?? false);
    final fetchedServices = ref.watch(vendorServicesProvider(vendor.id));
    final services = vendor.services.isNotEmpty ? vendor.services : (fetchedServices.value ?? const []);

    return DefaultTabController(
      length: 2,
      child: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            foregroundColor: Colors.white,
            backgroundColor: AppColors.ink,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            leading: const Padding(
              padding: EdgeInsets.all(4),
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                child: BackButton(color: Colors.white),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  AppImage(vendor.heroImage, placeholderSeed: vendor.businessName, placeholderIcon: categoryIcon(vendor.category)),
                  const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.scrim)),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      UserAvatar(name: vendor.businessName, url: vendor.profilePicture, size: 64, ring: true),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(child: Text(vendor.businessName, style: theme.textTheme.titleLarge)),
                                if (vendor.isApproved) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.verified_rounded, color: AppColors.info, size: 20),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              [vendor.category, vendor.ownerName].whereType<String>().join(' · '),
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: _Metric(value: vendor.rating > 0 ? vendor.rating.toStringAsFixed(1) : 'New', label: 'Rating', icon: Icons.star_rounded, color: AppColors.star)),
                      Expanded(child: _Metric(value: Fmt.compact(vendor.reviewCount), label: 'Reviews', icon: Icons.reviews_rounded, color: AppColors.violet)),
                      Expanded(child: _Metric(value: Fmt.compact(vendor.completedJobs), label: 'Events', icon: Icons.celebration_rounded, color: AppColors.primary)),
                    ],
                  ),
                  if (vendor.description != null) ...[
                    const SizedBox(height: 18),
                    Text(vendor.description!, style: theme.textTheme.bodyLarge),
                  ],
                  if (vendor.address != null || vendor.phone != null) ...[
                    const SizedBox(height: 12),
                    if (vendor.address != null) InfoRow(icon: Icons.place_rounded, title: vendor.address!, subtitle: 'Based in'),
                    if (vendor.phone != null)
                      InfoRow(
                        icon: Icons.call_rounded,
                        title: vendor.phone!,
                        subtitle: 'Phone',
                        trailing: IconButton(
                          icon: const Icon(Icons.copy_rounded),
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: vendor.phone!));
                            if (context.mounted) showSnack(context, 'Phone number copied');
                          },
                        ),
                      ),
                  ],
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => context.push(
                      Routes.chat(vendor.userId, name: vendor.businessName, avatar: vendor.profilePicture),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: const Text('Message vendor'),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabHeader(
              TabBar(tabs: [
                Tab(text: 'Services (${services.length})'),
                Tab(text: 'Portfolio (${vendor.portfolio.length})'),
              ]),
              theme.scaffoldBackgroundColor,
            ),
          ),
        ],
        body: TabBarView(
          children: [
            services.isEmpty
                ? (fetchedServices.isLoading
                    ? const SkeletonList(count: 2)
                    : const EmptyState(icon: Icons.design_services_rounded, title: 'No services listed yet'))
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: services.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _ServiceCard(
                      service: services[i],
                      onBook: canBook ? () => context.push(Routes.book(vendor.id, services[i].id)) : null,
                    ),
                  ),
            vendor.portfolio.isEmpty
                ? const EmptyState(icon: Icons.photo_library_rounded, title: 'No portfolio yet')
                : GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                    ),
                    itemCount: vendor.portfolio.length,
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => showPortfolioViewer(context, vendor.portfolio, i),
                      child: Hero(
                        tag: 'portfolio-${vendor.portfolio[i].id}',
                        child: AppImage(vendor.portfolio[i].mediaUrl, borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label, required this.icon, required this.color});

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(value, style: theme.textTheme.titleLarge),
          ],
        ),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, required this.onBook});

  final VendorService service;
  final VoidCallback? onBook;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(service.name, style: theme.textTheme.titleMedium),
            if (service.description != null) ...[
              const SizedBox(height: 6),
              Text(service.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Text.rich(TextSpan(children: [
                  TextSpan(
                    text: Fmt.money(service.basePrice),
                    style: theme.textTheme.titleLarge?.copyWith(color: AppColors.primary),
                  ),
                  TextSpan(
                    text: ' ${service.unitLabel}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ])),
                const Spacer(),
                if (onBook != null)
                  FilledButton(
                    onPressed: onBook,
                    style: FilledButton.styleFrom(minimumSize: const Size(96, 42)),
                    child: const Text('Book'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TabHeader extends SliverPersistentHeaderDelegate {
  _TabHeader(this.tabBar, this.background);

  final TabBar tabBar;
  final Color background;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      ColoredBox(color: background, child: tabBar);

  @override
  bool shouldRebuild(_TabHeader oldDelegate) => oldDelegate.tabBar != tabBar;
}

/// Full-screen swipeable image viewer.
void showPortfolioViewer(BuildContext context, List<PortfolioItem> items, int initial) {
  Navigator.of(context).push(PageRouteBuilder(
    opaque: false,
    barrierColor: Colors.black,
    pageBuilder: (_, _, _) => _PortfolioViewer(items: items, initial: initial),
    transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
  ));
}

class _PortfolioViewer extends StatefulWidget {
  const _PortfolioViewer({required this.items, required this.initial});

  final List<PortfolioItem> items;
  final int initial;

  @override
  State<_PortfolioViewer> createState() => _PortfolioViewerState();
}

class _PortfolioViewerState extends State<_PortfolioViewer> {
  late final _controller = PageController(initialPage: widget.initial);
  late int _index = widget.initial;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.items[_index];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Text('${_index + 1} of ${widget.items.length}', style: const TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.items.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => InteractiveViewer(
                child: Hero(
                  tag: 'portfolio-${widget.items[i].id}',
                  child: AppImage(widget.items[i].mediaUrl, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          if (item.caption != null)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(item.caption!, style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
        ],
      ),
    );
  }
}
