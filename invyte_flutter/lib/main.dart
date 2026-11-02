import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/di/core_providers.dart';
import 'core/storage/token_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final prefs = await SharedPreferences.getInstance();
  final tokens = await TokenStore.open(prefs);

  // Attribution for the bundled demo photos (Profile → About → View licenses).
  LicenseRegistry.addLicense(() async* {
    final credits = await rootBundle.loadString('assets/demo/CREDITS.md');
    yield LicenseEntryWithLineBreaks(['Invyte demo photos'], credits);
  });

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        tokenStoreProvider.overrideWithValue(tokens),
      ],
      // Errors are surfaced in the UI with a retry button instead.
      retry: (_, _) => null,
      child: const InvyteApp(),
    ),
  );
}
