import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/common.dart';
import '../../domain/entities/event.dart';

/// Large image card used in horizontal carousels.
class EventHeroCard extends StatelessWidget {
  const EventHeroCard({super.key, required this.event, this.width = 290, this.height = 220});

  final Event event;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Card(
        child: InkWell(
          onTap: () => context.push(Routes.event(event.id)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: 'event-cover-${event.id}',
                child: AppImage(event.coverImage, placeholderSeed: event.name),
              ),
              const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.scrim)),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    if (event.isLive)
                      LiveBadge(viewers: Fmt.compact(event.viewCount))
                    else
                      _DateBadge(date: event.date),
                    const Spacer(),
                    if (event.isPrivate) const _GlassIcon(icon: Icons.lock_rounded),
                  ],
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, height: 1.15),
                    ),
                    const SizedBox(height: 6),
                    _MetaLine(
                      icon: Icons.place_rounded,
                      text: event.venue ?? 'Venue to be announced',
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact list row with a thumbnail.
class EventListTile extends StatelessWidget {
  const EventListTile({super.key, required this.event, this.trailing});

  final Event event;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: () => context.push(Routes.event(event.id)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 84,
                height: 84,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppImage(event.coverImage, placeholderSeed: event.name, borderRadius: BorderRadius.circular(16)),
                    if (event.isLive) const Positioned(left: 6, top: 6, child: LiveBadge()),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Fmt.countdown(event.date).toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(event.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 6),
                    _MetaLine(
                      icon: Icons.schedule_rounded,
                      text: '${Fmt.shortDate(event.date)} · ${Fmt.time(event.startTime)}',
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 2),
                    _MetaLine(
                      icon: Icons.place_outlined,
                      text: event.venue ?? 'Venue TBA',
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              trailing ?? Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.date});

  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(Fmt.day(date),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.ink, height: 1)),
          Text(Fmt.monthShort(date),
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primary, letterSpacing: 0.8)),
        ],
      ),
    );
  }
}

class _GlassIcon extends StatelessWidget {
  const _GlassIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 16),
    );
  }
}
