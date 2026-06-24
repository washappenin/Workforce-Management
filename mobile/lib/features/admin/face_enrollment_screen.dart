import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/states.dart';
import 'admin_models.dart';
import 'admin_repository.dart';
import 'widgets/admin_widgets.dart';

const _faceStatuses = [
  'PENDING',
  'ACTIVE',
  'DISABLED',
  'FAILED',
];

class FaceEnrollmentScreen extends ConsumerWidget {
  const FaceEnrollmentScreen({super.key, required this.employeeId});

  final String employeeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employee = ref.watch(employeeProvider(employeeId));
    final enrollment = ref.watch(faceEnrollmentProvider(employeeId));
    return AdminPage(
      title: 'Face enrollment',
      subtitle: 'Safe provider status for attendance verification.',
      child: employee.when(
        loading: () => const LoadingState(label: 'Loading employee...'),
        error: (error, _) => adminErrorView(
          error,
          () => ref.invalidate(employeeProvider(employeeId)),
        ),
        data: (item) => enrollment.when(
          loading: () => const LoadingState(label: 'Loading face status...'),
          error: (error, _) => adminErrorView(
            error,
            () => ref.invalidate(faceEnrollmentProvider(employeeId)),
          ),
          data: (face) => ListView(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.fullName,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      InfoRow(label: 'Email', value: item.email),
                      InfoRow(label: 'Employee code', value: item.employeeCode),
                      InfoRow(
                          label: 'Provider', value: face.provider ?? 'mock'),
                      InfoRow(label: 'Status', value: face.status),
                      InfoRow(
                        label: 'Enrolled',
                        value: face.enrolledAt ?? 'Not enrolled',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'FE4 does not capture faces. This screen sends safe mock-provider enrollment metadata only. Raw images, biometric vectors, templates, and provider references are never stored on device or displayed after submit.',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _showFaceEnrollmentSheet(context, item),
                icon: const Icon(Icons.face_retouching_natural_outlined),
                label: Text(
                    face.exists ? 'Update enrollment' : 'Create enrollment'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: face.exists
                    ? () => _showFaceStatusSheet(context, item, face)
                    : null,
                icon: const Icon(Icons.published_with_changes_outlined),
                label: const Text('Change enrollment status'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showFaceEnrollmentSheet(
  BuildContext context,
  AdminEmployee employee,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _FaceEnrollmentFormSheet(employee: employee),
  );
}

Future<void> _showFaceStatusSheet(
  BuildContext context,
  AdminEmployee employee,
  FaceEnrollment enrollment,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        _FaceStatusSheet(employee: employee, enrollment: enrollment),
  );
}

class _FaceEnrollmentFormSheet extends ConsumerStatefulWidget {
  const _FaceEnrollmentFormSheet({required this.employee});

  final AdminEmployee employee;

  @override
  ConsumerState<_FaceEnrollmentFormSheet> createState() =>
      _FaceEnrollmentFormSheetState();
}

class _FaceEnrollmentFormSheetState
    extends ConsumerState<_FaceEnrollmentFormSheet> {
  final _providerSubject = TextEditingController();
  final _templateReference = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _providerSubject.dispose();
    _templateReference.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Mock enrollment',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Optional provider references are write-only in the client.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            const TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Provider',
                hintText: 'mock',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _providerSubject,
              decoration: const InputDecoration(
                labelText: 'Provider subject optional',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _templateReference,
              decoration: const InputDecoration(
                labelText: 'Template reference optional',
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save enrollment'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(adminRepositoryProvider).upsertFaceEnrollment(
            widget.employee.id,
            providerSubjectId: _providerSubject.text,
            templateReference: _templateReference.text,
          );
      ref.invalidate(faceEnrollmentProvider(widget.employee.id));
      if (!mounted) return;
      Navigator.of(context).pop();
      showSuccessSnack(context, 'Face enrollment saved.');
    } catch (error) {
      if (mounted) showFailureSnack(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _FaceStatusSheet extends ConsumerStatefulWidget {
  const _FaceStatusSheet({
    required this.employee,
    required this.enrollment,
  });

  final AdminEmployee employee;
  final FaceEnrollment enrollment;

  @override
  ConsumerState<_FaceStatusSheet> createState() => _FaceStatusSheetState();
}

class _FaceStatusSheetState extends ConsumerState<_FaceStatusSheet> {
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _status = _faceStatuses.contains(widget.enrollment.status)
        ? widget.enrollment.status
        : 'ACTIVE';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Enrollment status',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: [
              for (final status in _faceStatuses)
                DropdownMenuItem(value: status, child: Text(status)),
            ],
            onChanged: (value) => setState(() => _status = value ?? 'ACTIVE'),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving...' : 'Save status'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(adminRepositoryProvider).updateFaceEnrollmentStatus(
            widget.employee.id,
            status: _status,
          );
      ref.invalidate(faceEnrollmentProvider(widget.employee.id));
      if (!mounted) return;
      Navigator.of(context).pop();
      showSuccessSnack(context, 'Face enrollment status updated.');
    } catch (error) {
      if (mounted) showFailureSnack(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
