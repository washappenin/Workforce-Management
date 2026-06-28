import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/states.dart';
import 'admin_models.dart';
import 'admin_repository.dart';
import 'widgets/admin_widgets.dart';

class GeofencesScreen extends ConsumerWidget {
  const GeofencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final geofences = ref.watch(geofencesProvider);
    return AdminPage(
      title: 'Geofences',
      subtitle: 'Circular worksites for attendance validation.',
      action: IconButton.filled(
        key: const ValueKey('admin.geofence.create'),
        tooltip: 'New geofence',
        onPressed: () => _showGeofenceSheet(context),
        icon: const Icon(Icons.add_location_alt_outlined),
      ),
      child: geofences.when(
        loading: () => const LoadingState(label: 'Loading geofences...'),
        error: (error, _) =>
            adminErrorView(error, () => ref.invalidate(geofencesProvider)),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.location_searching_outlined,
              title: 'No geofences configured',
              message: 'Create an active geofence before employee clock-in.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(geofencesProvider),
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final geofence = items[index];
                return Card(
                  child: ListTile(
                    key: ValueKey('admin.geofence.item.${geofence.id}'),
                    onTap: () => context.go('/admin/geofences/${geofence.id}'),
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(geofence.name),
                    subtitle: Text(
                      '${_coordinate(geofence.latitude)}, ${_coordinate(geofence.longitude)} - ${geofence.radiusMeters} m',
                    ),
                    trailing: StatusPill(
                      label: geofence.status,
                      active: geofence.isActive,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class GeofenceDetailScreen extends ConsumerWidget {
  const GeofenceDetailScreen({super.key, required this.geofenceId});

  final String geofenceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final geofence = ref.watch(geofenceProvider(geofenceId));
    return AdminPage(
      title: 'Geofence',
      subtitle: 'Circular attendance boundary.',
      child: geofence.when(
        loading: () => const LoadingState(label: 'Loading geofence...'),
        error: (error, _) => adminErrorView(
          error,
          () => ref.invalidate(geofenceProvider(geofenceId)),
        ),
        data: (item) => ListView(
          children: [
            ElevatedButton.icon(
              key: const ValueKey('admin.geofence.edit'),
              onPressed: () => _showGeofenceSheet(context, existing: item),
              icon: const Icon(Icons.edit_location_alt_outlined),
              label: const Text('Edit geofence'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const ValueKey('admin.geofence.toggleStatus'),
              onPressed: item.status == 'ARCHIVED'
                  ? null
                  : () => _toggleGeofenceStatus(context, ref, item),
              icon: Icon(item.isActive
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline),
              label: Text(item.isActive ? 'Deactivate' : 'Activate'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const ValueKey('admin.geofence.archive'),
              onPressed: item.status == 'ARCHIVED'
                  ? null
                  : () => _archiveGeofence(context, ref, item),
              icon: const Icon(Icons.archive_outlined),
              label: const Text('Archive geofence'),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        StatusPill(label: item.status, active: item.isActive),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InfoRow(
                        label: 'Latitude', value: _coordinate(item.latitude)),
                    InfoRow(
                        label: 'Longitude', value: _coordinate(item.longitude)),
                    InfoRow(label: 'Radius', value: '${item.radiusMeters} m'),
                    InfoRow(label: 'Company', value: item.companyId),
                    InfoRow(label: 'Record', value: item.id),
                    if (item.updatedAt != null)
                      InfoRow(
                          label: 'Updated', value: _dateTime(item.updatedAt)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showGeofenceSheet(
  BuildContext context, {
  AdminGeofence? existing,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _GeofenceFormSheet(existing: existing),
  );
}

Future<void> _toggleGeofenceStatus(
  BuildContext context,
  WidgetRef ref,
  AdminGeofence geofence,
) async {
  final nextStatus = geofence.isActive ? 'INACTIVE' : 'ACTIVE';
  final confirmed = await confirmAction(
    context,
    title: geofence.isActive ? 'Deactivate geofence?' : 'Activate geofence?',
    message: geofence.isActive
        ? 'Employees will no longer be able to use this boundary for attendance.'
        : 'This boundary can be used for attendance validation.',
    confirmLabel: geofence.isActive ? 'Deactivate' : 'Activate',
  );
  if (!confirmed || !context.mounted) return;
  await _setGeofenceStatus(context, ref, geofence, nextStatus);
}

Future<void> _archiveGeofence(
  BuildContext context,
  WidgetRef ref,
  AdminGeofence geofence,
) async {
  final confirmed = await confirmAction(
    context,
    title: 'Archive geofence?',
    message:
        'Historical attendance remains intact, but this boundary will no longer be active.',
    confirmLabel: 'Archive',
  );
  if (!confirmed || !context.mounted) return;
  await _setGeofenceStatus(context, ref, geofence, 'ARCHIVED');
}

Future<void> _setGeofenceStatus(
  BuildContext context,
  WidgetRef ref,
  AdminGeofence geofence,
  String status,
) async {
  try {
    await ref
        .read(adminRepositoryProvider)
        .updateGeofenceStatus(geofence.id, status: status);
    ref.invalidate(geofencesProvider);
    ref.invalidate(geofenceProvider(geofence.id));
    if (context.mounted) showSuccessSnack(context, 'Geofence status updated.');
  } catch (error) {
    if (context.mounted) showFailureSnack(context, error);
  }
}

class _GeofenceFormSheet extends ConsumerStatefulWidget {
  const _GeofenceFormSheet({this.existing});

  final AdminGeofence? existing;

  @override
  ConsumerState<_GeofenceFormSheet> createState() => _GeofenceFormSheetState();
}

class _GeofenceFormSheetState extends ConsumerState<_GeofenceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;
  late final TextEditingController _radius;
  String _status = 'ACTIVE';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _latitude = TextEditingController(
      text: existing == null ? '' : _coordinate(existing.latitude),
    );
    _longitude = TextEditingController(
      text: existing == null ? '' : _coordinate(existing.longitude),
    );
    _radius = TextEditingController(
      text: existing == null ? '' : existing.radiusMeters.toString(),
    );
    _status = existing?.status ?? 'ACTIVE';
  }

  @override
  void dispose() {
    _name.dispose();
    _latitude.dispose();
    _longitude.dispose();
    _radius.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              editing ? 'Edit geofence' : 'New geofence',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('admin.geofence.name'),
              controller: _name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('admin.geofence.latitude'),
              controller: _latitude,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [_coordinateFormatter()],
              decoration: const InputDecoration(labelText: 'Latitude'),
              validator: (value) => _numberRange(value, -90, 90),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('admin.geofence.longitude'),
              controller: _longitude,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [_coordinateFormatter()],
              decoration: const InputDecoration(labelText: 'Longitude'),
              validator: (value) => _numberRange(value, -180, 180),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('admin.geofence.radius'),
              controller: _radius,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Radius meters'),
              validator: (value) => _intRange(value, 1, 50000),
            ),
            if (!editing) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const ValueKey('admin.geofence.status'),
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
                  DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
                  DropdownMenuItem(value: 'ARCHIVED', child: Text('Archived')),
                ],
                onChanged: (value) =>
                    setState(() => _status = value ?? 'ACTIVE'),
              ),
            ],
            const SizedBox(height: 18),
            ElevatedButton(
              key: const ValueKey('admin.geofence.save'),
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save geofence'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final existing = widget.existing;
      final latitude = double.parse(_latitude.text);
      final longitude = double.parse(_longitude.text);
      final radius = int.parse(_radius.text);
      if (existing == null) {
        await repo.createGeofence(
          name: _name.text,
          latitude: latitude,
          longitude: longitude,
          radiusMeters: radius,
          status: _status,
        );
      } else {
        await repo.updateGeofence(
          existing.id,
          name: _name.text,
          latitude: latitude,
          longitude: longitude,
          radiusMeters: radius,
        );
        ref.invalidate(geofenceProvider(existing.id));
      }
      ref.invalidate(geofencesProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showSuccessSnack(context, 'Geofence saved.');
    } catch (error) {
      if (mounted) showFailureSnack(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

TextInputFormatter _coordinateFormatter() {
  return FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'));
}

String? _required(String? value) {
  return value == null || value.trim().isEmpty ? 'Required' : null;
}

String? _numberRange(String? value, double min, double max) {
  final text = value?.trim() ?? '';
  final parsed = double.tryParse(text);
  if (parsed == null) return 'Enter a number';
  if (parsed < min || parsed > max) return 'Must be between $min and $max';
  return null;
}

String? _intRange(String? value, int min, int max) {
  final text = value?.trim() ?? '';
  final parsed = int.tryParse(text);
  if (parsed == null) return 'Enter a whole number';
  if (parsed < min || parsed > max) return 'Must be between $min and $max';
  return null;
}

String _coordinate(double value) => value.toStringAsFixed(6);

String _dateTime(String? value) {
  if (value == null || value.isEmpty) return 'Not recorded';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  return parsed.toLocal().toString().split('.').first;
}
