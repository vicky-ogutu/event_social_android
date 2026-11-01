import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/di/core_providers.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import 'router.dart';

class InvyteApp extends ConsumerWidget {
  const InvyteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Tell the user why they were signed out.
    ref.listen(authControllerProvider.select((s) => s.sessionExpired), (_, expired) {
      if (!expired) return;
      _messengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Your session expired. Please sign in again.')),
      );
    });

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: router,
    );
  }
}

final _messengerKey = GlobalKey<ScaffoldMessengerState>();
