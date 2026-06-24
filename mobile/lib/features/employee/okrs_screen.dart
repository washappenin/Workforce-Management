import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/states.dart';
import 'employee_models.dart';
import 'employee_repository.dart';
import 'widgets/employee_widgets.dart';

class OkrsScreen extends ConsumerWidget {
  const OkrsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final okrs = ref.watch(okrsProvider);

    return EmployeePage(
      title: 'OKRs',
      subtitle: 'Objectives and progress',
      action: IconButton.outlined(
        tooltip: 'Refresh',
        onPressed: () => ref.invalidate(okrsProvider),
        icon: const Icon(Icons.refresh),
      ),
      child: okrs.when(
        loading: () => const LoadingState(label: 'Loading OKRs...'),
        error: (error, _) => employeeErrorView(
          error,
          () => ref.invalidate(okrsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.track_changes_outlined,
              title: 'No OKRs assigned',
              message: 'Assigned objectives will appear here.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(okrsProvider);
              await ref.read(okrsProvider.future);
            },
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final okr = items[index];
                return SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              okr.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          StatusChip(label: okr.status),
                        ],
                      ),
                      if (okr.description != null) ...[
                        const SizedBox(height: 8),
                        Text(okr.description!),
                      ],
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          value: okr.progressPercent / 100,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('${okr.progressPercent}% complete'),
                      const Divider(height: 28),
                      InfoLine(label: 'Due', value: shortDate(okr.dueDate)),
                      InfoLine(
                        label: 'Approved',
                        value: okr.employeeApproved
                            ? 'Employee approved'
                            : 'Pending',
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            key: ValueKey('employee.okr.progress.${okr.id}'),
                            onPressed: () => _showProgressSheet(context, okr),
                            icon: const Icon(Icons.trending_up),
                            label: const Text('Update progress'),
                          ),
                          OutlinedButton.icon(
                            key: ValueKey('employee.okr.approve.${okr.id}'),
                            onPressed: okr.employeeApproved
                                ? null
                                : () => _showApproveSheet(context, okr),
                            icon: const Icon(Icons.verified_outlined),
                            label: const Text('Approve'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _showProgressSheet(BuildContext context, OkrItem okr) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OkrProgressSheet(okr: okr),
    );
  }

  Future<void> _showApproveSheet(BuildContext context, OkrItem okr) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OkrApproveSheet(okr: okr),
    );
  }
}

class _OkrProgressSheet extends ConsumerStatefulWidget {
  const _OkrProgressSheet({required this.okr});

  final OkrItem okr;

  @override
  ConsumerState<_OkrProgressSheet> createState() => _OkrProgressSheetState();
}

class _OkrProgressSheetState extends ConsumerState<_OkrProgressSheet> {
  final _formKey = GlobalKey<FormState>();
  final _progress = TextEditingController();
  final _note = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _progress.text = '${widget.okr.progressPercent}';
  }

  @override
  void dispose() {
    _progress.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Update progress',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(widget.okr.title),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('employee.okr.progressPercent'),
                controller: _progress,
                decoration: const InputDecoration(
                  labelText: 'Progress percent',
                  suffixText: '%',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                validator: (value) {
                  final parsed = int.tryParse(value ?? '');
                  if (parsed == null) return 'Enter a number';
                  if (parsed < 0 || parsed > 100) return 'Use 0 through 100';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('employee.okr.note'),
                controller: _note,
                decoration: const InputDecoration(
                  labelText: 'Progress note',
                  hintText: 'Optional',
                ),
                maxLines: 3,
                maxLength: 1000,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                key: const ValueKey('employee.okr.submitProgress'),
                onPressed: _saving ? null : _submit,
                child: Text(_saving ? 'Saving...' : 'Save progress'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(employeeRepositoryProvider).updateOkrProgress(
            widget.okr.id,
            progressPercent: int.parse(_progress.text),
            note: _note.text,
          );
      ref.invalidate(okrsProvider);
      ref.invalidate(okrProvider(widget.okr.id));
      if (!mounted) return;
      Navigator.of(context).pop();
      showEmployeeSuccessSnack(context, 'Progress updated.');
    } catch (error) {
      if (mounted) showEmployeeFailureSnack(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _OkrApproveSheet extends ConsumerStatefulWidget {
  const _OkrApproveSheet({required this.okr});

  final OkrItem okr;

  @override
  ConsumerState<_OkrApproveSheet> createState() => _OkrApproveSheetState();
}

class _OkrApproveSheetState extends ConsumerState<_OkrApproveSheet> {
  final _comment = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Approve OKR',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(widget.okr.title),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('employee.okr.approvalComment'),
              controller: _comment,
              decoration: const InputDecoration(
                labelText: 'Comment',
                hintText: 'Optional',
              ),
              maxLines: 3,
              maxLength: 1000,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              key: const ValueKey('employee.okr.submitApproval'),
              onPressed: _saving ? null : _submit,
              child: Text(_saving ? 'Approving...' : 'Approve OKR'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await ref.read(employeeRepositoryProvider).employeeApproveOkr(
            widget.okr.id,
            comment: _comment.text,
          );
      ref.invalidate(okrsProvider);
      ref.invalidate(okrProvider(widget.okr.id));
      if (!mounted) return;
      Navigator.of(context).pop();
      showEmployeeSuccessSnack(context, 'OKR approved.');
    } catch (error) {
      if (mounted) showEmployeeFailureSnack(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
