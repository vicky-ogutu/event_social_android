import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Renders remote (`http`), local (`file://`) or missing images with a
/// branded placeholder, so screens never show a broken image.
class AppImage extends StatelessWidget {
  const AppImage(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholderSeed = '',
    this.placeholderIcon = Icons.celebration_rounded,
  });

  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final String placeholderSeed;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final src = url;
    final Widget child;
    if (src == null || src.isEmpty) {
      child = _fallback();
    } else if (src.startsWith('asset://')) {
      // Bundled images (demo content) — available offline.
      child = Image.asset(
        src.substring('asset://'.length),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => _fallback(),
      );
    } else if (src.startsWith('file://')) {
      child = Image.file(
        File(Uri.parse(src).toFilePath()),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => _fallback(),
      );
    } else {
      child = CachedNetworkImage(
        imageUrl: src,
        fit: fit,
        width: width,
        height: height,
        fadeInDuration: const Duration(milliseconds: 250),
        placeholder: (context, _) => Container(color: Theme.of(context).colorScheme.surfaceContainerHigh),
        errorWidget: (_, _, _) => _fallback(),
      );
    }
    return borderRadius == null ? child : ClipRRect(borderRadius: borderRadius!, child: child);
  }

  Widget _fallback() {
    final accent = AppColors.accentFor(placeholderSeed);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, Color.lerp(accent, AppColors.violet, 0.6)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(child: Icon(placeholderIcon, color: Colors.white70, size: 36)),
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.url, this.size = 44, this.ring = false});

  final String name;
  final String? url;
  final double size;
  final bool ring;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentFor(name);
    final avatar = ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: (url == null || url!.isEmpty)
            ? Container(
                color: accent.withValues(alpha: 0.16),
                alignment: Alignment.center,
                child: Text(
                  _initials,
                  style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: size * 0.36),
                ),
              )
            : AppImage(url, placeholderSeed: name, placeholderIcon: Icons.person_rounded),
      ),
    );
    if (!ring) return avatar;
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.brandGradient),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.surface),
        child: avatar,
      ),
    );
  }
}
