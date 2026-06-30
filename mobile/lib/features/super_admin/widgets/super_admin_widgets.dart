import 'package:flutter/material.dart';

import '../../../core/errors/failures.dart';
import '../../../shared/widgets/states.dart';
import '../../employee/widgets/employee_widgets.dart';

export '../../employee/widgets/employee_widgets.dart'
    show
        EmployeePage,
        InfoLine,
        MetricTile,
        SectionCard,
        StatusChip,
        dayCount,
        shortDate,
        shortDateTime,
        statusColor,
        titleCase;

class SuperAdminPage extends EmployeePage {
  const SuperAdminPage({
    super.key,
    required super.title,
    super.subtitle,
    super.action,
    required super.child,
  });
}

Widget superAdminErrorView(Object error, VoidCallback onRetry) {
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

void showSuperAdminFailureSnack(BuildContext context, Object error) {
  showEmployeeFailureSnack(context, error);
}

void showSuperAdminSuccessSnack(BuildContext context, String message) {
  showEmployeeSuccessSnack(context, message);
}

class SuperAdminActionRow extends StatelessWidget {
  const SuperAdminActionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

String money(double value, String currency) {
  final amount = value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
  return '$amount $currency';
}
