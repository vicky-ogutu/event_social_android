import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/common.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  static const _slides = [
    (
      icon: Icons.celebration_rounded,
      accent: AppColors.primary,
      title: 'Plan unforgettable events',
      body: 'Weddings, launches, birthdays or brunch: create your event in minutes and keep every detail in one place.',
    ),
    (
      icon: Icons.storefront_rounded,
      accent: AppColors.violet,
      title: 'Book trusted vendors',
      body: 'Discover top-rated photographers, caterers, DJs and more. Compare, chat and book securely in-app.',
    ),
    (
      icon: Icons.live_tv_rounded,
      accent: Color(0xFFFF6B3D),
      title: 'Share the moment, live',
      body: 'Stream your event to guests anywhere, chat in real time and relive the highlights together.',
    ),
  ];

  Future<void> _finish() async {
    await ref.read(localStorageProvider).setOnboarded();
    if (mounted) context.go(Routes.login);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last = _page == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 12, 0),
              child: Row(
                children: [
                  const BrandLogo(size: 32, showWordmark: true),
                  const Spacer(),
                  if (!last) TextButton(onPressed: _finish, child: const Text('Skip')),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final slide = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Illustration(icon: slide.icon, accent: slide.accent),
                        const SizedBox(height: 48),
                        Text(slide.title, textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 16),
                        Text(
                          slide.body,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page ? AppColors.primary : theme.colorScheme.outline,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: PrimaryButton(
                label: last ? 'Get started' : 'Next',
                icon: last ? Icons.arrow_forward_rounded : null,
                onPressed: last
                    ? _finish
                    : () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final (size, alpha) in [(240.0, 0.06), (180.0, 0.1), (124.0, 0.16)])
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withValues(alpha: alpha)),
            ),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [accent, Color.lerp(accent, AppColors.violet, 0.5)!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 12))],
            ),
            child: Icon(icon, color: Colors.white, size: 46),
          ),
        ],
      ),
    );
  }
}
