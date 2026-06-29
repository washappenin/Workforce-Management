import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/states.dart';
import 'admin_models.dart';
import 'admin_repository.dart';
import 'widgets/admin_widgets.dart';

const _cycleStatuses = ['DRAFT', 'ACTIVE', 'CLOSED', 'ARCHIVED'];
const _reviewStatuses = ['DRAFT', 'SUBMITTED', 'ACKNOWLEDGED', 'ARCHIVED'];

class AdminReviewsScreen extends ConsumerStatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  ConsumerState<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends ConsumerState<AdminReviewsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Reviews',
      subtitle: 'Cycles and company performance reviews.',
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(key: ValueKey('admin.reviews.tab.cycles'), text: 'Cycles'),
              Tab(key: ValueKey('admin.reviews.tab.reviews'), text: 'Reviews'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _ReviewCyclesTab(),
                _ReviewsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCyclesTab extends ConsumerWidget {
  const _ReviewCyclesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cycles = ref.watch(adminReviewCyclesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          key: const ValueKey('admin.reviewCycle.create'),
          onPressed: () => _showReviewCycleSheet(context),
          icon: const Icon(Icons.add_outlined),
          label: const Text('New review cycle'),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: cycles.when(
            loading: () =>
                const LoadingState(label: 'Loading review cycles...'),
            error: (error, _) => adminErrorView(
              error,
              () => ref.invalidate(adminReviewCyclesProvider),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const EmptyState(
                  icon: Icons.event_repeat_outlined,
                  title: 'No review cycles',
                  message: 'Create and activate a cycle before reviews.',
                );
              }
              return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(adminReviewCyclesProvider),
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _ReviewCycleCard(
                    cycle: items[index],
                    onEdit: () =>
                        _showReviewCycleSheet(context, existing: items[index]),
                    onStatus: () =>
                        _showReviewCycleStatusSheet(context, items[index]),
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

class _ReviewCycleCard extends StatelessWidget {
  const _ReviewCycleCard({
    required this.cycle,
    required this.onEdit,
    required this.onStatus,
  });

  final AdminReviewCycle cycle;
  final VoidCallback onEdit;
  final VoidCallback onStatus;

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
                    cycle.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                StatusPill(label: cycle.status, active: cycle.isActive),
              ],
            ),
            const SizedBox(height: 10),
            InfoRow(
              label: 'Window',
              value:
                  '${_dateOnly(cycle.startDate)} - ${_dateOnly(cycle.endDate)}',
            ),
            InfoRow(label: 'Created', value: _dateTime(cycle.createdAt)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: ValueKey('admin.reviewCycle.edit.${cycle.name}'),
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    key: ValueKey(
                      'admin.reviewCycle.changeStatus.${cycle.name}',
                    ),
                    onPressed: onStatus,
                    icon: const Icon(Icons.published_with_changes_outlined),
                    label: const Text('Change status'),
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

class _ReviewsTab extends ConsumerStatefulWidget {
  const _ReviewsTab();

  @override
  ConsumerState<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends ConsumerState<_ReviewsTab> {
  String? _status;

  @override
  Widget build(BuildContext context) {
    final reviews = ref.watch(adminReviewsProvider(_status));
    final employees = ref.watch(employeesProvider).valueOrNull ?? const [];
    final employeeNames = {
      for (final employee in employees) employee.id: employee.fullName,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          key: const ValueKey('admin.review.create'),
          onPressed: () => _showReviewSheet(context),
          icon: const Icon(Icons.rate_review_outlined),
          label: const Text('Submit review'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          key: const ValueKey('admin.review.statusFilter'),
          initialValue: _status,
          decoration: const InputDecoration(labelText: 'Status filter'),
          items: const [
            DropdownMenuItem<String?>(
              value: null,
              child: Text('All reviews'),
            ),
            DropdownMenuItem(value: 'DRAFT', child: Text('Draft')),
            DropdownMenuItem(value: 'SUBMITTED', child: Text('Submitted')),
            DropdownMenuItem(
                value: 'ACKNOWLEDGED', child: Text('Acknowledged')),
            DropdownMenuItem(value: 'ARCHIVED', child: Text('Archived')),
          ],
          onChanged: (value) => setState(() => _status = value),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: reviews.when(
            loading: () => const LoadingState(label: 'Loading reviews...'),
            error: (error, _) => adminErrorView(
              error,
              () => ref.invalidate(adminReviewsProvider(_status)),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const EmptyState(
                  icon: Icons.rate_review_outlined,
                  title: 'No reviews',
                  message: 'Submitted company reviews will appear here.',
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(adminReviewsProvider(_status));
                  ref.invalidate(employeesProvider);
                  ref.invalidate(adminReviewCyclesProvider);
                },
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final review = items[index];
                    return _ReviewCard(
                      review: review,
                      employeeName: employeeNames[review.employeeId],
                      managerName: employeeNames[review.managerId],
                      onEdit: review.isEditable
                          ? () => _showReviewSheet(
                                context,
                                existing: review,
                                currentFilter: _status,
                              )
                          : null,
                      onStatus: () => _showReviewStatusSheet(
                        context,
                        review,
                        currentFilter: _status,
                      ),
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

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.employeeName,
    required this.managerName,
    required this.onEdit,
    required this.onStatus,
  });

  final AdminPerformanceReview review;
  final String? employeeName;
  final String? managerName;
  final VoidCallback? onEdit;
  final VoidCallback onStatus;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    review.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                StatusPill(
                  label: review.status,
                  active: review.status != 'ARCHIVED',
                ),
              ],
            ),
            const SizedBox(height: 10),
            InfoRow(
              label: 'Employee',
              value: employeeName ?? review.employeeId,
            ),
            InfoRow(
              label: 'Reviewer',
              value: managerName ?? review.managerId,
            ),
            InfoRow(
              label: 'Rating',
              value: review.rating == null
                  ? 'Not rated'
                  : review.rating!.toStringAsFixed(1),
            ),
            InfoRow(label: 'Submitted', value: _dateTime(review.submittedAt)),
            const Divider(height: 24),
            Text(
              review.summary,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: ValueKey('admin.review.edit.${review.title}'),
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    key: ValueKey('admin.review.changeStatus.${review.title}'),
                    onPressed: onStatus,
                    icon: const Icon(Icons.published_with_changes_outlined),
                    label: const Text('Change status'),
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

Future<void> _showReviewCycleSheet(
  BuildContext context, {
  AdminReviewCycle? existing,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ReviewCycleFormSheet(existing: existing),
  );
}

Future<void> _showReviewCycleStatusSheet(
  BuildContext context,
  AdminReviewCycle cycle,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ReviewCycleStatusSheet(cycle: cycle),
  );
}

Future<void> _showReviewSheet(
  BuildContext context, {
  AdminPerformanceReview? existing,
  String? currentFilter,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ReviewFormSheet(
      existing: existing,
      currentFilter: currentFilter,
    ),
  );
}

Future<void> _showReviewStatusSheet(
  BuildContext context,
  AdminPerformanceReview review, {
  String? currentFilter,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ReviewStatusSheet(
      review: review,
      currentFilter: currentFilter,
    ),
  );
}

class _ReviewCycleFormSheet extends ConsumerStatefulWidget {
  const _ReviewCycleFormSheet({this.existing});

  final AdminReviewCycle? existing;

  @override
  ConsumerState<_ReviewCycleFormSheet> createState() =>
      _ReviewCycleFormSheetState();
}

class _ReviewCycleFormSheetState extends ConsumerState<_ReviewCycleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _startDate;
  late final TextEditingController _endDate;
  bool _saving = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _startDate = TextEditingController(text: _dateInput(existing?.startDate));
    _endDate = TextEditingController(text: _dateInput(existing?.endDate));
  }

  @override
  void dispose() {
    _name.dispose();
    _startDate.dispose();
    _endDate.dispose();
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
              _editing ? 'Edit review cycle' : 'New review cycle',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('admin.reviewCycle.name'),
              controller: _name,
              textInputAction: TextInputAction.next,
              maxLength: 200,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('admin.reviewCycle.startDate'),
              controller: _startDate,
              keyboardType: TextInputType.datetime,
              inputFormatters: [LengthLimitingTextInputFormatter(10)],
              decoration: const InputDecoration(
                labelText: 'Start date',
                hintText: 'YYYY-MM-DD',
              ),
              validator: (value) => _dateValidator(value, optional: false),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('admin.reviewCycle.endDate'),
              controller: _endDate,
              keyboardType: TextInputType.datetime,
              inputFormatters: [LengthLimitingTextInputFormatter(10)],
              decoration: const InputDecoration(
                labelText: 'End date',
                hintText: 'YYYY-MM-DD',
              ),
              validator: _endDateValidator,
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              key: const ValueKey('admin.reviewCycle.save'),
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save review cycle'),
            ),
          ],
        ),
      ),
    );
  }

  String? _endDateValidator(String? value) {
    final error = _dateValidator(value, optional: false);
    if (error != null) return error;
    final start = DateTime.tryParse(_startDate.text);
    final end = DateTime.tryParse(value?.trim() ?? '');
    if (start != null && end != null && end.isBefore(start)) {
      return 'End date must be after start';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final existing = widget.existing;
      if (existing == null) {
        await repo.createReviewCycle(
          name: _name.text,
          startDate: _startDate.text,
          endDate: _endDate.text,
        );
      } else {
        await repo.updateReviewCycle(
          existing.id,
          name: _name.text,
          startDate: _startDate.text,
          endDate: _endDate.text,
        );
        ref.invalidate(adminReviewCycleProvider(existing.id));
      }
      ref.invalidate(adminReviewCyclesProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showSuccessSnack(context, 'Review cycle saved.');
    } catch (error) {
      if (mounted) showFailureSnack(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ReviewCycleStatusSheet extends ConsumerStatefulWidget {
  const _ReviewCycleStatusSheet({required this.cycle});

  final AdminReviewCycle cycle;

  @override
  ConsumerState<_ReviewCycleStatusSheet> createState() =>
      _ReviewCycleStatusSheetState();
}

class _ReviewCycleStatusSheetState
    extends ConsumerState<_ReviewCycleStatusSheet> {
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.cycle.status;
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
          Text(
            'Change cycle status',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: const ValueKey('admin.reviewCycle.status'),
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: [
              for (final status in _cycleStatuses)
                DropdownMenuItem(value: status, child: Text(status)),
            ],
            onChanged: (value) =>
                setState(() => _status = value ?? widget.cycle.status),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            key: const ValueKey('admin.reviewCycle.statusSave'),
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
      await ref.read(adminRepositoryProvider).updateReviewCycleStatus(
            widget.cycle.id,
            status: _status,
          );
      ref.invalidate(adminReviewCyclesProvider);
      ref.invalidate(adminReviewCycleProvider(widget.cycle.id));
      if (!mounted) return;
      Navigator.of(context).pop();
      showSuccessSnack(context, 'Review cycle status updated.');
    } catch (error) {
      if (mounted) showFailureSnack(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ReviewFormSheet extends ConsumerStatefulWidget {
  const _ReviewFormSheet({this.existing, this.currentFilter});

  final AdminPerformanceReview? existing;
  final String? currentFilter;

  @override
  ConsumerState<_ReviewFormSheet> createState() => _ReviewFormSheetState();
}

class _ReviewFormSheetState extends ConsumerState<_ReviewFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _employeeSearch = TextEditingController();
  final _cycleSearch = TextEditingController();
  late final TextEditingController _summary;
  late final TextEditingController _rating;
  String? _employeeId;
  String? _reviewCycleId;
  bool _saving = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _employeeId = existing?.employeeId;
    _reviewCycleId = existing?.reviewCycleId;
    _cycleSearch.text = existing?.title ?? '';
    _summary = TextEditingController(text: existing?.summary ?? '');
    _rating = TextEditingController(
      text: existing?.rating == null ? '' : existing!.rating!.toString(),
    );
  }

  @override
  void dispose() {
    _employeeSearch.dispose();
    _cycleSearch.dispose();
    _summary.dispose();
    _rating.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(employeesProvider);
    final cycles = ref.watch(adminReviewCyclesProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _editing ? 'Edit review' : 'Submit review',
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
                    key: const ValueKey('admin.review.employeePicker'),
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
                    itemKeyPrefix: 'admin.review.employee',
                    onSelected: (employee) =>
                        setState(() => _employeeId = employee.id),
                  ),
                ),
              const SizedBox(height: 12),
              if (_editing)
                InfoRow(label: 'Cycle', value: _cycleSearch.text)
              else
                cycles.when(
                  loading: () =>
                      const LoadingState(label: 'Loading review cycles...'),
                  error: (error, _) => adminErrorView(
                    error,
                    () => ref.invalidate(adminReviewCyclesProvider),
                  ),
                  data: (items) => _SelectableSearchList<AdminReviewCycle>(
                    key: const ValueKey('admin.review.cyclePicker'),
                    title: 'Review cycle',
                    searchController: _cycleSearch,
                    selectedId: _reviewCycleId,
                    items: items
                        .where((cycle) => cycle.status == 'ACTIVE')
                        .toList(growable: false),
                    idOf: (cycle) => cycle.id,
                    labelOf: _cycleLabel,
                    searchOf: (cycle) =>
                        '${cycle.name} ${cycle.status} ${cycle.startDate} ${cycle.endDate}',
                    itemKeyPrefix: 'admin.review.cycle',
                    onSelected: (cycle) =>
                        setState(() => _reviewCycleId = cycle.id),
                  ),
                ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('admin.review.summary'),
                controller: _summary,
                maxLength: 4000,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Summary'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('admin.review.rating'),
                controller: _rating,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_decimalFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Rating optional',
                  hintText: '1-5',
                ),
                validator: _ratingValidator,
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                key: const ValueKey('admin.review.save'),
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving...' : 'Save review'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_editing && (_employeeId == null || _reviewCycleId == null)) {
      _showInlineFailure(context, 'Choose an employee and active cycle.');
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final rating = _optionalDouble(_rating.text);
      final existing = widget.existing;
      if (existing == null) {
        await repo.submitManagerReview(
          employeeId: _employeeId!,
          reviewCycleId: _reviewCycleId!,
          summary: _summary.text,
          rating: rating,
        );
      } else {
        await repo.updateReview(
          existing.id,
          summary: _summary.text,
          rating: rating,
        );
        ref.invalidate(adminReviewProvider(existing.id));
      }
      _invalidateReviewLists(ref, widget.currentFilter);
      if (!mounted) return;
      Navigator.of(context).pop();
      showSuccessSnack(context, 'Performance review saved.');
    } catch (error) {
      if (mounted) showFailureSnack(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ReviewStatusSheet extends ConsumerStatefulWidget {
  const _ReviewStatusSheet({required this.review, this.currentFilter});

  final AdminPerformanceReview review;
  final String? currentFilter;

  @override
  ConsumerState<_ReviewStatusSheet> createState() => _ReviewStatusSheetState();
}

class _ReviewStatusSheetState extends ConsumerState<_ReviewStatusSheet> {
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.review.status;
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
          Text('Change status', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: const ValueKey('admin.review.status'),
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: [
              for (final status in _reviewStatuses)
                DropdownMenuItem(value: status, child: Text(status)),
            ],
            onChanged: (value) =>
                setState(() => _status = value ?? widget.review.status),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            key: const ValueKey('admin.review.statusSave'),
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
      await ref.read(adminRepositoryProvider).updateReviewStatus(
            widget.review.id,
            status: _status,
          );
      ref.invalidate(adminReviewProvider(widget.review.id));
      _invalidateReviewLists(ref, widget.currentFilter);
      if (!mounted) return;
      Navigator.of(context).pop();
      showSuccessSnack(context, 'Performance review status updated.');
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

void _invalidateReviewLists(WidgetRef ref, String? currentFilter) {
  ref.invalidate(adminReviewsProvider(null));
  if (currentFilter != null) {
    ref.invalidate(adminReviewsProvider(currentFilter));
  }
  for (final status in _reviewStatuses) {
    ref.invalidate(adminReviewsProvider(status));
  }
  ref.invalidate(adminReviewCyclesProvider);
}

void _showInlineFailure(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String? _required(String? value) {
  return value == null || value.trim().isEmpty ? 'Required' : null;
}

String? _dateValidator(String? value, {required bool optional}) {
  final text = value?.trim() ?? '';
  if (optional && text.isEmpty) return null;
  final valid = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text);
  return valid ? null : 'Use YYYY-MM-DD';
}

String? _ratingValidator(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  final parsed = double.tryParse(text);
  if (parsed == null) return 'Enter a number';
  if (parsed < 1 || parsed > 5) return 'Must be between 1 and 5';
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

String _cycleLabel(AdminReviewCycle cycle) {
  return '${cycle.name} (${_dateOnly(cycle.startDate)} - ${_dateOnly(cycle.endDate)})';
}

String _dateInput(String? value) {
  if (value == null || value.isEmpty) return '';
  return value.length >= 10 ? value.substring(0, 10) : value;
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
