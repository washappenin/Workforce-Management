import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/states.dart';
import 'admin_models.dart';
import 'admin_repository.dart';
import 'widgets/admin_widgets.dart';

class AdminLeaveScreen extends ConsumerStatefulWidget {
  const AdminLeaveScreen({super.key});

  @override
  ConsumerState<AdminLeaveScreen> createState() => _AdminLeaveScreenState();
}

class _AdminLeaveScreenState extends ConsumerState<AdminLeaveScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Leave',
      subtitle: 'Types, balances, and request review.',
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(key: ValueKey('admin.leave.tab.types'), text: 'Types'),
              Tab(
                key: ValueKey('admin.leave.tab.entitlements'),
                text: 'Balances',
              ),
              Tab(key: ValueKey('admin.leave.tab.requests'), text: 'Requests'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _LeaveTypesTab(),
                _LeaveEntitlementsTab(),
                _LeaveRequestsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaveTypesTab extends ConsumerWidget {
  const _LeaveTypesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaveTypes = ref.watch(leaveTypesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          key: const ValueKey('admin.leaveType.create'),
          onPressed: () => _showLeaveTypeSheet(context),
          icon: const Icon(Icons.add_outlined),
          label: const Text('New leave type'),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: leaveTypes.when(
            loading: () => const LoadingState(label: 'Loading leave types...'),
            error: (error, _) => adminErrorView(
              error,
              () => ref.invalidate(leaveTypesProvider),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const EmptyState(
                  icon: Icons.beach_access_outlined,
                  title: 'No leave types',
                  message: 'Create leave types before assigning balances.',
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(leaveTypesProvider),
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _LeaveTypeCard(
                    leaveType: items[index],
                    onEdit: () =>
                        _showLeaveTypeSheet(context, existing: items[index]),
                    onToggle: () =>
                        _toggleLeaveTypeStatus(context, ref, items[index]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LeaveTypeCard extends StatelessWidget {
  const _LeaveTypeCard({
    required this.leaveType,
    required this.onEdit,
    required this.onToggle,
  });

  final AdminLeaveType leaveType;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final allowance = leaveType.defaultAnnualAllowance == null
        ? 'No default allowance'
        : '${_dayCount(leaveType.defaultAnnualAllowance!)} days default';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    leaveType.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                StatusPill(label: leaveType.status, active: leaveType.isActive),
              ],
            ),
            const SizedBox(height: 10),
            Text(allowance, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: ValueKey('admin.leaveType.edit.${leaveType.id}'),
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    key: ValueKey('admin.leaveType.toggle.${leaveType.id}'),
                    onPressed: onToggle,
                    icon: Icon(leaveType.isActive
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline),
                    label: Text(leaveType.isActive ? 'Disable' : 'Enable'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaveEntitlementsTab extends ConsumerWidget {
  const _LeaveEntitlementsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlements = ref.watch(leaveEntitlementsProvider);
    final employees = ref.watch(employeesProvider).valueOrNull ?? const [];
    final employeeNames = {
      for (final employee in employees) employee.id: employee.fullName,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          key: const ValueKey('admin.leaveEntitlement.create'),
          onPressed: () => _showLeaveEntitlementSheet(context),
          icon: const Icon(Icons.account_balance_wallet_outlined),
          label: const Text('Assign balance'),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: entitlements.when(
            loading: () =>
                const LoadingState(label: 'Loading leave balances...'),
            error: (error, _) => adminErrorView(
              error,
              () => ref.invalidate(leaveEntitlementsProvider),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const EmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'No leave balances',
                  message: 'Assign employee entitlements for a leave year.',
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(leaveEntitlementsProvider);
                  ref.invalidate(employeesProvider);
                  ref.invalidate(leaveTypesProvider);
                },
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _EntitlementCard(
                      entitlement: item,
                      employeeName: employeeNames[item.employeeId],
                      onEdit: () =>
                          _showLeaveEntitlementSheet(context, existing: item),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EntitlementCard extends StatelessWidget {
  const _EntitlementCard({
    required this.entitlement,
    required this.employeeName,
    required this.onEdit,
  });

  final AdminLeaveEntitlement entitlement;
  final String? employeeName;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entitlement.leaveTypeName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  '${entitlement.year}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: 10),
            InfoRow(
              label: 'Employee',
              value: employeeName ?? entitlement.employeeId,
            ),
            InfoRow(
              label: 'Remaining',
              value: '${_dayCount(entitlement.remainingDays)} days',
            ),
            InfoRow(
              label: 'Used',
              value: '${_dayCount(entitlement.usedDays)} days',
            ),
            InfoRow(
              label: 'Total',
              value: '${_dayCount(entitlement.totalDays)} days',
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: ValueKey('admin.leaveEntitlement.edit.${entitlement.id}'),
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit balance'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaveRequestsTab extends ConsumerStatefulWidget {
  const _LeaveRequestsTab();

  @override
  ConsumerState<_LeaveRequestsTab> createState() => _LeaveRequestsTabState();
}

class _LeaveRequestsTabState extends ConsumerState<_LeaveRequestsTab> {
  String? _status = 'PENDING';

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(adminLeaveRequestsProvider(_status));
    final employees = ref.watch(employeesProvider).valueOrNull ?? const [];
    final employeeNames = {
      for (final employee in employees) employee.id: employee.fullName,
    };

    return Column(
      children: [
        DropdownButtonFormField<String?>(
          key: const ValueKey('admin.leaveRequest.statusFilter'),
          initialValue: _status,
          decoration: const InputDecoration(labelText: 'Status filter'),
          items: const [
            DropdownMenuItem<String?>(
              value: null,
              child: Text('All requests'),
            ),
            DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
            DropdownMenuItem(value: 'APPROVED', child: Text('Approved')),
            DropdownMenuItem(value: 'REJECTED', child: Text('Rejected')),
          ],
          onChanged: (value) => setState(() => _status = value),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: requests.when(
            loading: () =>
                const LoadingState(label: 'Loading leave requests...'),
            error: (error, _) => adminErrorView(
              error,
              () => ref.invalidate(adminLeaveRequestsProvider(_status)),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const EmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'No leave requests',
                  message: 'Employee requests will appear here for review.',
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(adminLeaveRequestsProvider(_status));
                  ref.invalidate(employeesProvider);
                },
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _LeaveRequestCard(
                      request: item,
                      employeeName: employeeNames[item.employeeId],
                      onApprove: item.isPending
                          ? () => _reviewLeaveRequest(
                                context,
                                ref,
                                item,
                                approve: true,
                                currentFilter: _status,
                              )
                          : null,
                      onReject: item.isPending
                          ? () => _reviewLeaveRequest(
                                context,
                                ref,
                                item,
                                approve: false,
                                currentFilter: _status,
                              )
                          : null,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LeaveRequestCard extends StatelessWidget {
  const _LeaveRequestCard({
    required this.request,
    required this.employeeName,
    required this.onApprove,
    required this.onReject,
  });

  final AdminLeaveRequest request;
  final String? employeeName;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.leaveTypeName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                StatusPill(label: request.status, active: request.isPending),
              ],
            ),
            const SizedBox(height: 10),
            InfoRow(
                label: 'Employee', value: employeeName ?? request.employeeId),
            InfoRow(
              label: 'Dates',
              value:
                  '${_dateOnly(request.startDate)} - ${_dateOnly(request.endDate)}',
            ),
            InfoRow(
              label: 'Days',
              value: _dayCount(request.requestedDays),
            ),
            if (request.reason != null)
              InfoRow(label: 'Reason', value: request.reason!),
            if (request.reviewedAt != null)
              InfoRow(label: 'Reviewed', value: _dateTime(request.reviewedAt)),
            if (request.reviewComment != null)
              InfoRow(label: 'Comment', value: request.reviewComment!),
            if (request.isPending) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      key: ValueKey('admin.leaveRequest.approve.${request.id}'),
                      onPressed: onApprove,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Approve'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: ValueKey('admin.leaveRequest.reject.${request.id}'),
                      onPressed: onReject,
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> _showLeaveTypeSheet(
  BuildContext context, {
  AdminLeaveType? existing,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _LeaveTypeFormSheet(existing: existing),
  );
}

Future<void> _showLeaveEntitlementSheet(
  BuildContext context, {
  AdminLeaveEntitlement? existing,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _LeaveEntitlementFormSheet(existing: existing),
  );
}

Future<void> _toggleLeaveTypeStatus(
  BuildContext context,
  WidgetRef ref,
  AdminLeaveType leaveType,
) async {
  final nextStatus = leaveType.isActive ? 'INACTIVE' : 'ACTIVE';
  final confirmed = await confirmAction(
    context,
    title: leaveType.isActive ? 'Disable leave type?' : 'Enable leave type?',
    message: leaveType.isActive
        ? 'Employees will no longer be able to request this leave type.'
        : 'Employees can request this leave type when they have balance.',
    confirmLabel: leaveType.isActive ? 'Disable' : 'Enable',
  );
  if (!confirmed || !context.mounted) return;
  try {
    await ref
        .read(adminRepositoryProvider)
        .updateLeaveTypeStatus(leaveType.id, status: nextStatus);
    ref.invalidate(leaveTypesProvider);
    ref.invalidate(leaveEntitlementsProvider);
    if (context.mounted) showSuccessSnack(context, 'Leave type updated.');
  } catch (error) {
    if (context.mounted) showFailureSnack(context, error);
  }
}

Future<void> _reviewLeaveRequest(
  BuildContext context,
  WidgetRef ref,
  AdminLeaveRequest request, {
  required bool approve,
  required String? currentFilter,
}) async {
  final comment = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(approve ? 'Approve request?' : 'Reject request?'),
      content: TextField(
        key: const ValueKey('admin.leaveRequest.reviewComment'),
        controller: comment,
        maxLength: 500,
        maxLines: 3,
        decoration: const InputDecoration(labelText: 'Comment optional'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const ValueKey('admin.leaveRequest.reviewSubmit'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(approve ? 'Approve' : 'Reject'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  try {
    final repo = ref.read(adminRepositoryProvider);
    if (approve) {
      await repo.approveLeaveRequest(request.id, comment: comment.text);
    } else {
      await repo.rejectLeaveRequest(request.id, comment: comment.text);
    }
    ref.invalidate(adminLeaveRequestsProvider(currentFilter));
    ref.invalidate(leaveEntitlementsProvider);
    if (context.mounted) {
      showSuccessSnack(
        context,
        approve ? 'Leave request approved.' : 'Leave request rejected.',
      );
    }
  } catch (error) {
    if (context.mounted) showFailureSnack(context, error);
  } finally {
    comment.dispose();
  }
}

class _LeaveTypeFormSheet extends ConsumerStatefulWidget {
  const _LeaveTypeFormSheet({this.existing});

  final AdminLeaveType? existing;

  @override
  ConsumerState<_LeaveTypeFormSheet> createState() =>
      _LeaveTypeFormSheetState();
}

class _LeaveTypeFormSheetState extends ConsumerState<_LeaveTypeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _allowance;
  bool _saving = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _allowance = TextEditingController(
      text: existing?.defaultAnnualAllowance == null
          ? ''
          : _dayCount(existing!.defaultAnnualAllowance!),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _allowance.dispose();
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
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              _editing ? 'Edit leave type' : 'New leave type',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('admin.leaveType.name'),
              controller: _name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('admin.leaveType.allowance'),
              controller: _allowance,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [_decimalFormatter()],
              decoration: const InputDecoration(
                labelText: 'Default annual allowance optional',
              ),
              validator: (value) => _dayCountValidator(value, optional: true),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              key: const ValueKey('admin.leaveType.save'),
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save leave type'),
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
      final allowance = _optionalDouble(_allowance.text);
      final repo = ref.read(adminRepositoryProvider);
      final existing = widget.existing;
      if (existing == null) {
        await repo.createLeaveType(
          name: _name.text,
          defaultAnnualAllowance: allowance,
        );
      } else {
        await repo.updateLeaveType(
          existing.id,
          name: _name.text,
          defaultAnnualAllowance: allowance,
        );
        ref.invalidate(leaveTypeProvider(existing.id));
      }
      ref.invalidate(leaveTypesProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showSuccessSnack(context, 'Leave type saved.');
    } catch (error) {
      if (mounted) showFailureSnack(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _LeaveEntitlementFormSheet extends ConsumerStatefulWidget {
  const _LeaveEntitlementFormSheet({this.existing});

  final AdminLeaveEntitlement? existing;

  @override
  ConsumerState<_LeaveEntitlementFormSheet> createState() =>
      _LeaveEntitlementFormSheetState();
}

class _LeaveEntitlementFormSheetState
    extends ConsumerState<_LeaveEntitlementFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _employeeSearch = TextEditingController();
  final _leaveTypeSearch = TextEditingController();
  late final TextEditingController _year;
  late final TextEditingController _totalDays;
  late final TextEditingController _usedDays;
  String? _employeeId;
  String? _leaveTypeId;
  bool _saving = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _employeeId = existing?.employeeId;
    _leaveTypeId = existing?.leaveTypeId;
    _leaveTypeSearch.text = existing?.leaveTypeName ?? '';
    _year = TextEditingController(
      text: existing?.year.toString() ?? DateTime.now().year.toString(),
    );
    _totalDays = TextEditingController(
      text: existing == null ? '' : _dayCount(existing.totalDays),
    );
    _usedDays = TextEditingController(
      text: existing == null ? '0' : _dayCount(existing.usedDays),
    );
  }

  @override
  void dispose() {
    _employeeSearch.dispose();
    _leaveTypeSearch.dispose();
    _year.dispose();
    _totalDays.dispose();
    _usedDays.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(employeesProvider);
    final leaveTypes = ref.watch(leaveTypesProvider);

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
              _editing ? 'Edit leave balance' : 'Assign leave balance',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (_editing)
              InfoRow(label: 'Employee', value: _employeeId ?? 'Employee')
            else
              employees.when(
                loading: () =>
                    const LoadingState(label: 'Loading employees...'),
                error: (error, _) => adminErrorView(
                  error,
                  () => ref.invalidate(employeesProvider),
                ),
                data: (items) => _SelectableSearchList<AdminEmployee>(
                  key: const ValueKey('admin.leaveEntitlement.employeePicker'),
                  title: 'Employee',
                  searchController: _employeeSearch,
                  selectedId: _employeeId,
                  items: items
                      .where((employee) => employee.status == 'ACTIVE')
                      .toList(growable: false),
                  idOf: (employee) => employee.id,
                  labelOf: _employeeLabel,
                  searchOf: (employee) =>
                      '${employee.fullName} ${employee.email} ${employee.employeeCode}',
                  itemKeyPrefix: 'admin.leaveEntitlement.employee',
                  onSelected: (employee) =>
                      setState(() => _employeeId = employee.id),
                ),
              ),
            const SizedBox(height: 12),
            if (_editing)
              InfoRow(label: 'Leave type', value: _leaveTypeSearch.text)
            else
              leaveTypes.when(
                loading: () =>
                    const LoadingState(label: 'Loading leave types...'),
                error: (error, _) => adminErrorView(
                  error,
                  () => ref.invalidate(leaveTypesProvider),
                ),
                data: (items) => _SelectableSearchList<AdminLeaveType>(
                  key: const ValueKey('admin.leaveEntitlement.typePicker'),
                  title: 'Leave type',
                  searchController: _leaveTypeSearch,
                  selectedId: _leaveTypeId,
                  items: items
                      .where((leaveType) => leaveType.isActive)
                      .toList(growable: false),
                  idOf: (leaveType) => leaveType.id,
                  labelOf: (leaveType) => leaveType.name,
                  searchOf: (leaveType) => leaveType.name,
                  itemKeyPrefix: 'admin.leaveEntitlement.leaveType',
                  onSelected: (leaveType) => setState(() {
                    _leaveTypeId = leaveType.id;
                    if (_totalDays.text.trim().isEmpty &&
                        leaveType.defaultAnnualAllowance != null) {
                      _totalDays.text =
                          _dayCount(leaveType.defaultAnnualAllowance!);
                    }
                  }),
                ),
              ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('admin.leaveEntitlement.year'),
              controller: _year,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Year'),
              validator: _yearValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('admin.leaveEntitlement.totalDays'),
              controller: _totalDays,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [_decimalFormatter()],
              decoration: const InputDecoration(labelText: 'Total days'),
              validator: (value) => _dayCountValidator(value, optional: false),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('admin.leaveEntitlement.usedDays'),
              controller: _usedDays,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [_decimalFormatter()],
              decoration: const InputDecoration(labelText: 'Used days'),
              validator: (value) {
                final error = _dayCountValidator(value, optional: false);
                if (error != null) return error;
                final total = double.tryParse(_totalDays.text) ?? 0;
                final used = double.tryParse(value ?? '') ?? 0;
                if (used > total) return 'Used cannot exceed total';
                return null;
              },
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              key: const ValueKey('admin.leaveEntitlement.save'),
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save balance'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_editing && (_employeeId == null || _leaveTypeId == null)) {
      showFailureSnack(context, const _SelectionFailure());
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final existing = widget.existing;
      if (existing == null) {
        await repo.upsertLeaveEntitlement(
          employeeId: _employeeId!,
          leaveTypeId: _leaveTypeId!,
          year: int.parse(_year.text),
          totalDays: double.parse(_totalDays.text),
          usedDays: double.parse(_usedDays.text),
        );
      } else {
        await repo.updateLeaveEntitlement(
          existing.id,
          totalDays: double.parse(_totalDays.text),
          usedDays: double.parse(_usedDays.text),
        );
        ref.invalidate(leaveEntitlementProvider(existing.id));
      }
      ref.invalidate(leaveEntitlementsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showSuccessSnack(context, 'Leave balance saved.');
    } catch (error) {
      if (mounted) showFailureSnack(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _SelectableSearchList<T> extends StatefulWidget {
  const _SelectableSearchList({
    super.key,
    required this.title,
    required this.searchController,
    required this.selectedId,
    required this.items,
    required this.idOf,
    required this.labelOf,
    required this.searchOf,
    required this.itemKeyPrefix,
    required this.onSelected,
  });

  final String title;
  final TextEditingController searchController;
  final String? selectedId;
  final List<T> items;
  final String Function(T item) idOf;
  final String Function(T item) labelOf;
  final String Function(T item) searchOf;
  final String itemKeyPrefix;
  final ValueChanged<T> onSelected;

  @override
  State<_SelectableSearchList<T>> createState() =>
      _SelectableSearchListState<T>();
}

class _SelectableSearchListState<T> extends State<_SelectableSearchList<T>> {
  @override
  Widget build(BuildContext context) {
    final term = widget.searchController.text.trim().toLowerCase();
    final filtered = term.isEmpty
        ? widget.items.take(5).toList(growable: false)
        : widget.items
            .where(
              (item) => widget.searchOf(item).toLowerCase().contains(term),
            )
            .take(8)
            .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: ValueKey('${widget.itemKeyPrefix}.search'),
          controller: widget.searchController,
          decoration: InputDecoration(labelText: '${widget.title} search'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        if (filtered.isEmpty)
          Text(
            'No matches',
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          for (final item in filtered)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                key: ValueKey('${widget.itemKeyPrefix}.${widget.idOf(item)}'),
                onPressed: () {
                  widget.onSelected(item);
                  widget.searchController.text = widget.labelOf(item);
                  setState(() {});
                },
                child: Row(
                  children: [
                    Icon(
                      widget.selectedId == widget.idOf(item)
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.labelOf(item),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _SelectionFailure {
  const _SelectionFailure();
}

String? _required(String? value) {
  return value == null || value.trim().isEmpty ? 'Required' : null;
}

String? _yearValidator(String? value) {
  final parsed = int.tryParse(value?.trim() ?? '');
  if (parsed == null) return 'Enter a year';
  if (parsed < 2000 || parsed > 2100) return 'Must be between 2000 and 2100';
  return null;
}

String? _dayCountValidator(String? value, {required bool optional}) {
  final text = value?.trim() ?? '';
  if (optional && text.isEmpty) return null;
  final parsed = double.tryParse(text);
  if (parsed == null) return 'Enter a number';
  if (parsed < 0 || parsed > 3650) return 'Must be between 0 and 3650';
  return null;
}

TextInputFormatter _decimalFormatter() {
  return FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'));
}

double? _optionalDouble(String value) {
  final text = value.trim();
  return text.isEmpty ? null : double.parse(text);
}

String _employeeLabel(AdminEmployee employee) {
  if (employee.fullName == employee.email) return employee.email;
  return '${employee.fullName} - ${employee.email}';
}

String _dayCount(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(1);
}

String _dateOnly(String? value) {
  if (value == null || value.isEmpty) return 'Not recorded';
  return value.length >= 10 ? value.substring(0, 10) : value;
}

String _dateTime(String? value) {
  if (value == null || value.isEmpty) return 'Not recorded';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  return parsed.toLocal().toString().split('.').first;
}
