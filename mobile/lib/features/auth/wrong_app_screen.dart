import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/auth/models.dart';
import '../../core/config/app_flavor.dart';
import '../../shared/widgets/states.dart';

class WrongAppScreen extends ConsumerWidget {
  const WrongAppScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flavor = ref.watch(flavorConfigProvider);
    final auth = ref.watch(authControllerProvider);
    final role =
        auth is AuthAuthenticated ? auth.user.primaryRole : AppRole.unknown;
    final targetApp = flavorForRole(role).appName;
    final roleLabel = role.label;

    return Scaffold(
      body: ErrorStateView(
        icon: Icons.apps_outlined,
        title: 'Wrong app',
        message:
            'This $roleLabel account belongs in $targetApp, not ${flavor.appName}.',
        onRetry: () {
          ref.read(authControllerProvider.notifier).logout();
        },
        actionLabel: 'Sign out',
      ),
    );
  }
}
