import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/states.dart';
import 'employee_models.dart';
import 'employee_repository.dart';
import 'widgets/employee_widgets.dart';

class LeaveScreen extends ConsumerWidget {
  const LeaveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leave = ref.watch(leaveSummaryProvider);

    return EmployeePage(
      title: 'Leave',
      subtitle: 'Balances and requests',
      action: leave.maybeWhen(
        data: (summary) => IconButton.outlined(
          key: const ValueKey('employee.leave.newRequest'),
          tooltip: 'Request leave',
          onPressed: summary.entitlements.isEmpty
              ? null
              : () => _showLeaveRequestSheet(context, summary),
          icon: const Icon(Icons.add),
        ),
        orElse: () => IconButton.outlined(
          tooltip: 'Refresh',
          onPressed: () => ref.invalidate(leaveSummaryProvider),
          icon: const Icon(Icons.refresh),
        ),
      ),
      child: leave.when(
        loading: () => const LoadingState(label: 'Loading leave...'),
        error: (error, _) => employeeErrorView(
          error,
          () => ref.invalidate(leaveSummaryProvider),
        ),
        data: (summary) {
          if (summary.entitlements.isEmpty && summary.leaveRequests.isEmpty) {
            return const EmptyState(
              icon: Icons.beach_access_outlined,
              title: 'No leave records',
              message:
                  'Leave balances and requests will appear after an entitlement is assigned.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(leaveSummaryProvider);
              await ref.read(leaveSummaryProvider.future);
            },
            child: ListView(
              children: [
                if (summary.entitlements.isNotEmpty) ...[
                  Text(
                    'Balances',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  for (final entitlement in summary.entitlements) ...[
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entitlement.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              StatusChip(
                                label:
                                    entitlement.leaveType?.status ?? 'ACTIVE',
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          InfoLine(
                            label: 'Remaining',
                            value:
                                '${dayCount(entitlement.remainingDays)} days',
                          ),
                          InfoLine(
                            label: 'Used',
                            value: '${dayCount(entitlement.usedDays)} days',
                          ),
                          InfoLine(
                            label: 'Annual',
                            value: '${dayCount(entitlement.totalDays)} days',
                          ),
                          InfoLine(
                            label: 'Year',
                            value: '${entitlement.year}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Requests',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey('employee.leave.requestButton'),
                      onPressed: summary.entitlements.isEmpty
                          ? null
                          : () => _showLeaveRequestSheet(context, summary),
                      icon: const Icon(Icons.add),
                      label: const Text('Request'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (summary.leaveRequests.isEmpty)
                  const EmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'No requests yet',
                    message: 'Submitted leave requests will appear here.',
                  )
                else
                  for (final request in summary.leaveRequests) ...[
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  request.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              StatusChip(label: request.status),
                            ],
                          ),
                          const Divider(height: 24),
                          InfoLine(
                            label: 'Dates',
                            value:
                                '${shortDate(request.startDate)} - ${shortDate(request.endDate)}',
                          ),
                          InfoLine(
                            label: 'Days',
                            value: dayCount(request.requestedDays),
                          ),
                          InfoLine(
                            label: 'Submitted',
                            value: shortDateTime(request.createdAt),
                          ),
                          if (request.reason != null)
                            InfoLine(label: 'Reason', value: request.reason!),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showLeaveRequestSheet(
    BuildContext context,
    LeaveSummary summary,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _LeaveRequestSheet(summary: summary),
    );
  }
}

class _LeaveRequestSheet extends ConsumerStatefulWidget {
  const _LeaveRequestSheet({required this.summary});

  final LeaveSummary summary;

  @override
  ConsumerState<_LeaveRequestSheet> createState() => _LeaveRequestSheetState();
}

class _LeaveRequestSheetState extends ConsumerState<_LeaveRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _startDate = TextEditingController();
  final _endDate = TextEditingController();
  final _reason = TextEditingController();
  String? _entitlementId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _entitlementId = widget.summary.entitlements.isEmpty
        ? null
        : widget.summary.entitlements.first.id;
  }

  @override
  void dispose() {
    _startDate.dispose();
    _endDate.dispose();
    _reason.dispose();
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
                'Request leave',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: const ValueKey('employee.leave.type'),
                initialValue: _entitlementId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Leave type'),
                items: [
                  for (final entitlement in widget.summary.entitlements)
                    DropdownMenuItem(
                      value: entitlement.id,
                      child: Text(
                        '${entitlement.name} (${dayCount(entitlement.remainingDays)} left)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                validator: (value) => value == null || value.isEmpty
                    ? 'Select a leave type'
                    : null,
                onChanged: (value) => setState(() => _entitlementId = value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('employee.leave.startDate'),
                controller: _startDate,
                decoration: const InputDecoration(
                  labelText: 'Start date',
                  hintText: 'YYYY-MM-DD',
                ),
                keyboardType: TextInputType.datetime,
                inputFormatters: [LengthLimitingTextInputFormatter(10)],
                validator: _dateValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('employee.leave.endDate'),
                controller: _endDate,
                decoration: const InputDecoration(
                  labelText: 'End date',
                  hintText: 'YYYY-MM-DD',
                ),
                keyboardType: TextInputType.datetime,
                inputFormatters: [LengthLimitingTextInputFormatter(10)],
                validator: (value) {
                  final dateError = _dateValidator(value);
                  if (dateError != null) return dateError;
                  if (_startDate.text.compareTo(_endDate.text) > 0) {
                    return 'End date must be on or after start date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('employee.leave.reason'),
                controller: _reason,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  hintText: 'Optional',
                ),
                maxLines: 3,
                maxLength: 1000,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                key: const ValueKey('employee.leave.submit'),
                onPressed: _saving ? null : _submit,
                child: Text(_saving ? 'Submitting...' : 'Submit request'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _dateValidator(String? value) {
    final text = value?.trim() ?? '';
    final valid = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text);
    return valid ? null : 'Use YYYY-MM-DD';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final entitlement = widget.summary.entitlements.firstWhere(
        (item) => item.id == _entitlementId,
      );
      await ref.read(employeeRepositoryProvider).submitLeaveRequest(
            leaveTypeId: entitlement.leaveTypeId,
            startDate: _startDate.text.trim(),
            endDate: _endDate.text.trim(),
            reason: _reason.text,
          );
      ref.invalidate(leaveSummaryProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showEmployeeSuccessSnack(context, 'Leave request submitted.');
    } catch (error) {
      if (mounted) showEmployeeFailureSnack(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
