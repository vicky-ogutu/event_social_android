import 'package:flutter/material.dart';

import '../error/failure.dart';
import '../theme/app_colors.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 56, this.showWordmark = false, this.light = false});

  final double size;
  final bool showWordmark;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: size * 0.4, offset: Offset(0, size * 0.12)),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(Icons.celebration_rounded, color: Colors.white, size: size * 0.55),
    );
    if (!showWordmark) return mark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: size * 0.25),
        Text(
          'invyte',
          style: TextStyle(
            fontSize: size * 0.6,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.2,
            color: light ? Colors.white : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.gradient = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final child = loading
        ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled || loading ? 1 : 0.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient ? AppColors.brandGradient : null,
          color: gradient ? null : AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.28), blurRadius: 18, offset: const Offset(0, 8))]
              : null,
        ),
        child: FilledButton(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledForegroundColor: Colors.white,
          ),
          child: child,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction, this.padding});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(20, 28, 12, 12),
      child: Row(
        children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color, this.icon, this.dense = false});

  final String label;
  final Color color;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: dense ? 12 : 14, color: color), const SizedBox(width: 4)],
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: dense ? 11 : 12),
          ),
        ],
      ),
    );
  }
}

class LiveBadge extends StatefulWidget {
  const LiveBadge({super.key, this.viewers});

  final String? viewers;

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: AppColors.live, borderRadius: BorderRadius.circular(6)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: _pulse,
                child: const CircleAvatar(radius: 3.5, backgroundColor: Colors.white),
              ),
              const SizedBox(width: 5),
              const Text('LIVE',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.8)),
            ],
          ),
        ),
        if (widget.viewers != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(6)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.visibility_rounded, size: 12, color: Colors.white),
                const SizedBox(width: 4),
                Text(widget.viewers!,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class RatingPill extends StatelessWidget {
  const RatingPill({super.key, required this.rating, this.reviews, this.onDark = false});

  final double rating;
  final int? reviews;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final muted = onDark ? Colors.white70 : Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: AppColors.star, size: 18),
        const SizedBox(width: 3),
        Text(
          rating > 0 ? rating.toStringAsFixed(1) : 'New',
          style: TextStyle(fontWeight: FontWeight.w800, color: onDark ? Colors.white : null),
        ),
        if (reviews != null && reviews! > 0) ...[
          const SizedBox(width: 4),
          Text('($reviews)', style: TextStyle(color: muted, fontSize: 13)),
        ],
      ],
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.icon, required this.title, this.subtitle, this.trailing});

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                if (subtitle != null)
                  Text(subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
    this.caption,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 14),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: theme.textTheme.headlineSmall),
            ),
            const SizedBox(height: 2),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            if (caption != null) ...[
              const SizedBox(height: 6),
              Text(caption!, style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Section container used on detail and form screens.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.title, this.padding = const EdgeInsets.all(18)});

  final Widget child;
  final String? title;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title!, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: error ? const Color(0xFFFF8A8A) : const Color(0xFF7CE0A3), size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    ));
}

void showErrorSnack(BuildContext context, Object error) => showSnack(context, describeError(error), error: true);

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            minimumSize: const Size(110, 46),
            backgroundColor: destructive ? AppColors.danger : AppColors.primary,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
