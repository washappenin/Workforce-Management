import 'package:flutter/material.dart';

import '../../../core/errors/failures.dart';
import '../../../core/theme/aurelia_theme.dart';
import '../../../shared/widgets/states.dart';

class EmployeePage extends StatelessWidget {
  const EmployeePage({
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
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
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

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AureliaColors.royal, size: 22),
            const SizedBox(height: 14),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AureliaColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.color,
  });

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? statusColor(label);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        border: Border.all(color: tone.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          titleCase(label),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: tone,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class InfoLine extends StatelessWidget {
  const InfoLine({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
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

Widget employeeErrorView(Object error, VoidCallback onRetry) {
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
  if (error is ValidationFailure) {
    return ErrorStateView(
      title: 'Could not save',
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

void showEmployeeFailureSnack(BuildContext context, Object error) {
  final message = error is AppFailure ? error.message : 'Action failed.';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AureliaColors.danger,
    ),
  );
}

void showEmployeeSuccessSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String titleCase(String value) {
  final words = value
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(' ')
      .where((word) => word.isNotEmpty);
  return words
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

String shortDate(String? value) {
  if (value == null || value.isEmpty) return 'Not set';
  if (value.length >= 10) return value.substring(0, 10);
  return value;
}

String shortDateTime(String? value) {
  if (value == null || value.isEmpty) return 'Not set';
  return value.replaceFirst('T', ' ').replaceFirst('.000Z', ' UTC');
}

String dayCount(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(1);
}

Color statusColor(String status) {
  return switch (status) {
    'ACTIVE' ||
    'OPEN' ||
    'APPROVED' ||
    'ACKNOWLEDGED' ||
    'CLOCKED_IN' =>
      AureliaColors.success,
    'PENDING' ||
    'ASSIGNED' ||
    'IN_PROGRESS' ||
    'SUBMITTED' =>
      AureliaColors.royal,
    'REJECTED' || 'CANCELLED' || 'TERMINATED' => AureliaColors.danger,
    _ => AureliaColors.muted,
  };
}
