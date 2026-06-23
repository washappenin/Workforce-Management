import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/router.dart';
import 'core/theme/aurelia_theme.dart';

class AureliaApp extends ConsumerWidget {
  const AureliaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Aurelia',
      debugShowCheckedModeBanner: false,
      theme: AureliaTheme.light(),
      darkTheme: AureliaTheme.dark(),
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
