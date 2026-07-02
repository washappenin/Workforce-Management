import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_flavor.dart';
import 'core/routing/router.dart';
import 'core/theme/aurelia_theme.dart';

void runAureliaApp({
  FlavorConfig flavorConfig = workforceFlavorConfig,
}) {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [flavorConfigProvider.overrideWithValue(flavorConfig)],
      child: const AureliaApp(),
    ),
  );
}

class AureliaApp extends ConsumerWidget {
  const AureliaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flavor = ref.watch(flavorConfigProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: flavor.appName,
      debugShowCheckedModeBanner: false,
      theme: AureliaTheme.light(),
      darkTheme: AureliaTheme.dark(),
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
