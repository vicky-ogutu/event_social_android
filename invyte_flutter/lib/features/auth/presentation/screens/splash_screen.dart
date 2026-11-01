import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/common.dart';
import '../providers/auth_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
    ..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), _continue);
  }

  void _continue() {
    if (!mounted) return;
    final user = ref.read(currentUserProvider);
    final onboarded = ref.read(localStorageProvider).hasOnboarded;
    context.go(switch ((user, onboarded)) {
      (final u?, _) => Routes.homeFor(vendor: u.isVendor),
      (null, false) => Routes.onboarding,
      (null, true) => Routes.login,
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.nightGradient),
        child: Center(
          child: FadeTransition(
            opacity: _controller,
            child: ScaleTransition(
              scale: Tween(begin: 0.8, end: 1.0).animate(curve),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandLogo(size: 84),
                  const SizedBox(height: 22),
                  const Text(
                    'invyte',
                    style: TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: -2),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppConfig.tagline,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 15, letterSpacing: 0.3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
