import 'package:flutter/material.dart';

import '../../../core/errors/failures.dart';
import '../../../core/theme/aurelia_theme.dart';
import '../../../shared/widgets/states.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.headlineMedium),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AureliaColors.muted),
                        ),
                      ],
                    ],
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(width: 12),
                  action!,
                ],
              ],
            ),
            const SizedBox(height: 18),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.active = true,
  });

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AureliaColors.success : AureliaColors.muted;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AureliaColors.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

Widget adminErrorView(Object error, VoidCallback onRetry) {
  if (error is ConnectionFailure) {
    return ConnectionErrorState(onRetry: onRetry);
  }
  if (error is ForbiddenFailure) {
    return AccessDeniedState(message: error.message);
  }
  if (error is NotFoundFailure) {
    return NotFoundState(message: error.message);
  }
  if (error is RateLimitedFailure) {
    return ErrorStateView(
      title: 'Rate limited',
      message: error.message,
      onRetry: onRetry,
    );
  }
  if (error is AppFailure) {
    return ErrorStateView(
      title: 'Could not load',
      message: error.message,
      onRetry: onRetry,
    );
  }
  return ErrorStateView(
    title: 'Could not load',
    message: 'Something unexpected happened.',
    onRetry: onRetry,
  );
}

void showFailureSnack(BuildContext context, Object error) {
  final message = error is AppFailure ? error.message : 'Action failed.';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AureliaColors.danger,
    ),
  );
}

void showSuccessSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
