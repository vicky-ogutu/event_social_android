import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/state_views.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../../events/presentation/widgets/event_cards.dart';
import '../../../vendors/domain/entities/vendor.dart';
import '../../../vendors/presentation/providers/vendor_providers.dart';
import '../../../vendors/presentation/widgets/vendor_cards.dart';

/// Marketplace search across vendors and public events.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 2, vsync: this);
  final _search = TextEditingController();
  Timer? _debounce;
  String? _query;
  String? _category;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
  }

  @override
  void didUpdateWidget(DiscoverScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Category taps on the home screen re-enter this tab with a new filter.
    if (widget.initialCategory != oldWidget.initialCategory && widget.initialCategory != null) {
      setState(() => _category = widget.initialCategory);
      _tabs.animateTo(0);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = value.trim().isEmpty ? null : value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: NestedScrollView(
          headerSliverBuilder: (_, _) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Discover', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _search,
                      onChanged: _onSearchChanged,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search vendors and events',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _search.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _search.clear();
                                  _onSearchChanged('');
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: TabBar(
                controller: _tabs,
                tabs: const [Tab(text: 'Vendors'), Tab(text: 'Events')],
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabs,
            children: [
              _VendorResults(
                query: _query,
                category: _category,
                onCategory: (c) => setState(() => _category = c),
              ),
              _EventResults(query: _query),
            ],
          ),
        ),
      ),
    );
  }
}

class _VendorResults extends ConsumerWidget {
  const _VendorResults({required this.query, required this.category, required this.onCategory});

  final String? query;
  final String? category;
  final ValueChanged<String?> onCategory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final vendorQuery = VendorQuery(search: query, category: category);
    final results = ref.watch(vendorSearchProvider(vendorQuery));

    return RefreshIndicator(
      onRefresh: () => ref.refresh(vendorSearchProvider(vendorQuery).future),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 64,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(label: 'All', selected: category == null, onTap: () => onCategory(null)),
                  for (final c in categories)
                    _FilterChip(
                      label: c.name,
                      icon: categoryIcon(c.name),
                      selected: category == c.name,
                      onTap: () => onCategory(category == c.name ? null : c.name),
                    ),
                ],
              ),
            ),
          ),
          ...results.when(
            data: (vendors) => vendors.isEmpty
                ? [
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No vendors found',
                        message: 'Try a different search or category.',
                      ),
                    ),
                  ]
                : [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      sliver: SliverList.separated(
                        itemCount: vendors.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (_, i) => VendorListTile(vendor: vendors[i]),
                      ),
                    ),
                  ],
            loading: () => [const SliverToBoxAdapter(child: SkeletonList(count: 3, itemHeight: 220, shrinkWrap: true))],
            error: (e, _) => [
              SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorState(message: e.toString(), onRetry: () => ref.invalidate(vendorSearchProvider(vendorQuery))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventResults extends ConsumerWidget {
  const _EventResults({required this.query});

  final String? query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventQuery = EventQuery(search: query);
    final results = ref.watch(discoverEventsProvider(eventQuery));
    return RefreshIndicator(
      onRefresh: () => ref.refresh(discoverEventsProvider(eventQuery).future),
      child: AsyncValueView(
        value: results,
        onRetry: () => ref.invalidate(discoverEventsProvider(eventQuery)),
        data: (List<Event> events) => events.isEmpty
            ? ListView(children: const [
                EmptyState(
                  icon: Icons.event_busy_rounded,
                  title: 'No public events match',
                  message: 'Try another search term.',
                ),
              ])
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                itemCount: events.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (_, i) => EventHeroCard(event: events[i], width: double.infinity, height: 210),
              ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
        avatar: icon == null ? null : Icon(icon, size: 16, color: selected ? Colors.white : null),
        label: Text(label),
        labelStyle: TextStyle(fontWeight: FontWeight.w600, color: selected ? Colors.white : null),
      ),
    );
  }
}
