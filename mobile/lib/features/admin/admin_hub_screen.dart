import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/aurelia_theme.dart';
import 'widgets/admin_widgets.dart';

class AdminHubScreen extends StatelessWidget {
  const AdminHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Admin setup',
      subtitle: 'Company structure and employee records.',
      child: ListView(
        children: const [
          _AdminHubTile(
            icon: Icons.account_tree_outlined,
            title: 'Departments',
            subtitle: 'Create teams and manage active department scope.',
            route: '/admin/departments',
          ),
          SizedBox(height: 12),
          _AdminHubTile(
            icon: Icons.badge_outlined,
            title: 'Designations',
            subtitle: 'Maintain job titles and optional department mapping.',
            route: '/admin/designations',
          ),
          SizedBox(height: 12),
          _AdminHubTile(
            icon: Icons.people_outline,
            title: 'Employees',
            subtitle: 'Provision staff, roles, managers, and profile status.',
            route: '/admin/employees',
          ),
          SizedBox(height: 12),
          _AdminHubTile(
            icon: Icons.location_on_outlined,
            title: 'Geofences',
            subtitle: 'Maintain circular worksites for attendance checks.',
            route: '/admin/geofences',
          ),
          SizedBox(height: 12),
          _AdminHubTile(
            icon: Icons.assignment_turned_in_outlined,
            title: 'Attendance',
            subtitle: 'Review company clock sessions and verification status.',
            route: '/admin/attendance',
          ),
          SizedBox(height: 12),
          _AdminHubTile(
            icon: Icons.schedule_outlined,
            title: 'Shifts',
            subtitle: 'Create work schedules and assign employee coverage.',
            route: '/admin/shifts',
          ),
          SizedBox(height: 12),
          _AdminHubTile(
            icon: Icons.beach_access_outlined,
            title: 'Leave',
            subtitle: 'Configure leave types, balances, and approvals.',
            route: '/admin/leave',
          ),
          SizedBox(height: 12),
          _AdminHubTile(
            icon: Icons.track_changes_outlined,
            title: 'OKRs',
            subtitle: 'Assign objectives and review completion approvals.',
            route: '/admin/okrs',
          ),
        ],
      ),
    );
  }
}

class _AdminHubTile extends StatelessWidget {
  const _AdminHubTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        key: ValueKey('admin.hub.$route'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go(route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AureliaColors.royal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AureliaColors.royal),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
