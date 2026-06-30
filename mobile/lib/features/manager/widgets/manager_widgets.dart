import 'package:flutter/material.dart';

import '../../../shared/widgets/states.dart';
import '../../employee/widgets/employee_widgets.dart';

export '../../employee/widgets/employee_widgets.dart'
    show
        InfoLine,
        MetricTile,
        SectionCard,
        StatusChip,
        dayCount,
        shortDate,
        shortDateTime,
        statusColor,
        titleCase;

class ManagerPage extends EmployeePage {
  const ManagerPage({
    super.key,
    required super.title,
    super.subtitle,
    super.action,
    required super.child,
  });
}

Widget managerErrorView(Object error, VoidCallback onRetry) {
  return employeeErrorView(error, onRetry);
}

void showManagerFailureSnack(BuildContext context, Object error) {
  showEmployeeFailureSnack(context, error);
}

void showManagerSuccessSnack(BuildContext context, String message) {
  showEmployeeSuccessSnack(context, message);
}

class ManagerActionRow extends StatelessWidget {
  const ManagerActionRow({
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

class ManagerEmptyList extends StatelessWidget {
  const ManagerEmptyList({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        EmptyState(icon: icon, title: title, message: message),
      ],
    );
  }
}
