import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/common.dart';
import '../../domain/entities/vendor.dart';

IconData categoryIcon(String? category) => switch (category?.toLowerCase()) {
      'photography' => Icons.photo_camera_rounded,
      'catering' => Icons.restaurant_rounded,
      'decor' => Icons.local_florist_rounded,
      'music & dj' => Icons.headphones_rounded,
      'venues' => Icons.villa_rounded,
      'beauty' => Icons.face_retouching_natural_rounded,
      'cakes & desserts' => Icons.cake_rounded,
      'transport' => Icons.directions_car_rounded,
      _ => Icons.storefront_rounded,
    };

Color categoryColor(String? category) => switch (category?.toLowerCase()) {
      'photography' => const Color(0xFF7C3AED),
      'catering' => const Color(0xFFF97316),
      'decor' => const Color(0xFFE91E63),
      'music & dj' => const Color(0xFF0EA5E9),
      'venues' => const Color(0xFF10B981),
      'beauty' => const Color(0xFFEC4899),
      'cakes & desserts' => const Color(0xFFF59E0B),
      'transport' => const Color(0xFF6366F1),
      _ => AppColors.primary,
    };

/// Vertical card for carousels.
class VendorCard extends StatelessWidget {
  const VendorCard({super.key, required this.vendor, this.width = 220});

  final Vendor vendor;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Card(
        child: InkWell(
          onTap: () => context.push(Routes.vendor(vendor.id)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 130,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppImage(vendor.heroImage, placeholderSeed: vendor.businessName, placeholderIcon: categoryIcon(vendor.category)),
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(100)),
                        child: RatingPill(rating: vendor.rating),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(vendor.businessName,
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
                        ),
                        if (vendor.isApproved) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, size: 16, color: AppColors.info),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vendor.category ?? 'Event services',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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

/// Full-width row for search results.
class VendorListTile extends StatelessWidget {
  const VendorListTile({super.key, required this.vendor});

  final Vendor vendor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Card(
      child: InkWell(
        onTap: () => context.push(Routes.vendor(vendor.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 150,
              width: double.infinity,
              child: AppImage(vendor.heroImage, placeholderSeed: vendor.businessName, placeholderIcon: categoryIcon(vendor.category)),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  UserAvatar(name: vendor.businessName, url: vendor.profilePicture, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(vendor.businessName,
                                  maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
                            ),
                            if (vendor.isApproved) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified_rounded, size: 16, color: AppColors.info),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(categoryIcon(vendor.category), size: 14, color: muted),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                [vendor.category, vendor.address].whereType<String>().join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(color: muted),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      RatingPill(rating: vendor.rating, reviews: vendor.reviewCount),
                      if (vendor.completedJobs > 0)
                        Text('${Fmt.compact(vendor.completedJobs)} events',
                            style: theme.textTheme.labelSmall?.copyWith(color: muted)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
