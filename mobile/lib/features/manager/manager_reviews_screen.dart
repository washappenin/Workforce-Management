import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/states.dart';
import 'manager_models.dart';
import 'manager_repository.dart';
import 'widgets/manager_widgets.dart';

const _reviewStatuses = ['DRAFT', 'SUBMITTED', 'ACKNOWLEDGED', 'ARCHIVED'];

class ManagerReviewsScreen extends ConsumerWidget {
  const ManagerReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(managerReviewsProvider);
    final report = ref.watch(managerPerformanceReportProvider);

    return ManagerPage(
      title: 'Reviews',
      subtitle: 'Direct-report performance',
      action: IconButton.outlined(
        key: const ValueKey('manager.review.create'),
        tooltip: 'New review',
        onPressed: () => _showReviewSheet(context, ref),
        icon: const Icon(Icons.add),
      ),
      child: _body(context, ref, reviews, report),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ManagerPerformanceReview>> reviews,
    AsyncValue<ManagerPerformanceReport> report,
  ) {
    if (reviews.isLoading || report.isLoading) {
      return const LoadingState(label: 'Loading team reviews...');
    }
    if (reviews.hasError) {
      return managerErrorView(
        reviews.error!,
        () => ref.invalidate(managerReviewsProvider),
      );
    }
    if (report.hasError) {
      return managerErrorView(
        report.error!,
        () => ref.invalidate(managerPerformanceReportProvider),
      );
    }

    final items = reviews.value!;
    final summary = report.value!;
    return RefreshIndicator(
      onRefresh: () async {
        _refresh(ref);
        await Future.wait([
          ref.read(managerReviewsProvider.future),
          ref.read(managerPerformanceReportProvider.future),
        ]);
      },
      child: ListView(
        children: [
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width > 720 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.18,
            children: [
              MetricTile(
                label: 'Reviews',
                value: '${summary.totalReviews}',
                icon: Icons.rate_review_outlined,
              ),
              MetricTile(
                label: 'Draft',
                value: '${summary.pendingReviews}',
                icon: Icons.edit_note_outlined,
              ),
              MetricTile(
                label: 'Submitted',
                value: '${summary.submittedReviews}',
                icon: Icons.outbox_outlined,
              ),
              MetricTile(
                label: 'Average',
                value: summary.averageRating == null
                    ? 'N/A'
                    : summary.averageRating!.toStringAsFixed(1),
                icon: Icons.star_outline,
              ),
            ],
          ),
          if (summary.reviewsByCycle.isNotEmpty) ...[
            const SizedBox(height: 14),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reviews by cycle',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  for (final cycle in summary.reviewsByCycle)
                    InfoLine(
                      label: cycle.reviewCycleName,
                      value: '${cycle.count}',
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (items.isEmpty)
            const EmptyState(
              icon: Icons.rate_review_outlined,
              title: 'No team reviews',
              message:
                  'Submit reviews when an active review cycle and direct report are available.',
            )
          else
            for (final review in items) ...[
              _ReviewCard(review: review),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class ManagerReviewDetailScreen extends ConsumerWidget {
  const ManagerReviewDetailScreen({super.key, required this.reviewId});

  final String reviewId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final review = ref.watch(managerReviewProvider(reviewId));

    return ManagerPage(
      title: 'Review detail',
      subtitle: 'Performance review',
      action: IconButton.outlined(
        tooltip: 'Refresh',
        onPressed: () => ref.invalidate(managerReviewProvider(reviewId)),
        icon: const Icon(Icons.refresh),
      ),
      child: review.when(
        loading: () => const LoadingState(label: 'Loading review...'),
        error: (error, _) => managerErrorView(
          error,
          () => ref.invalidate(managerReviewProvider(reviewId)),
        ),
        data: (item) => ListView(children: [_ReviewCard(review: item)]),
      ),
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  const _ReviewCard({required this.review});

  final ManagerPerformanceReview review;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  review.reviewCycle?.name ?? 'Performance review',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              StatusChip(label: review.status),
            ],
          ),
          const SizedBox(height: 8),
          InfoLine(
            label: 'Employee',
            value: review.employee?.label ??
                'Employee ${shortId(review.employeeId)}',
          ),
          InfoLine(
            label: 'Rating',
            value: review.rating == null
                ? 'Not rated'
                : review.rating!.toStringAsFixed(1),
          ),
          InfoLine(
              label: 'Submitted', value: shortDateTime(review.submittedAt)),
          const Divider(height: 24),
          Text(review.summary),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: ValueKey('manager.review.edit.${review.id}'),
                onPressed: review.isEditable
                    ? () => _showReviewSheet(context, ref, existing: review)
                    : null,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
              OutlinedButton.icon(
                key: ValueKey('manager.review.status.${review.id}'),
                onPressed: () => _showStatusSheet(context, ref, review),
                icon: const Icon(Icons.swap_horiz_outlined),
                label: const Text('Status'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _showReviewSheet(
  BuildContext context,
  WidgetRef ref, {
  ManagerPerformanceReview? existing,
}) async {
  final formKey = GlobalKey<FormState>();
  final members = await ref.read(managerTeamMembersProvider.future);
  final reviews = await ref.read(managerReviewsProvider.future);
  if (!context.mounted) return;
  final cycles = _cyclesFromReviews(reviews);
  final employee = TextEditingController(
    text: existing?.employeeId ?? (members.isEmpty ? '' : members.first.id),
  );
  final cycle = TextEditingController(
    text: existing?.reviewCycleId ?? (cycles.isEmpty ? '' : cycles.first.id),
  );
  final summary = TextEditingController(text: existing?.summary ?? '');
  final rating = TextEditingController(
    text: existing?.rating == null ? '' : existing!.rating!.toStringAsFixed(1),
  );
  var selectedEmployeeId = employee.text;
  var selectedCycleId = cycle.text;

  try {
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existing == null ? 'New review' : 'Edit review'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (existing == null && members.isNotEmpty)
                    DropdownButtonFormField<String>(
                      key: const ValueKey('manager.review.employee.dropdown'),
                      initialValue: selectedEmployeeId,
                      decoration: const InputDecoration(labelText: 'Employee'),
                      items: [
                        for (final member in members)
                          DropdownMenuItem(
                            value: member.id,
                            child: Text(member.label),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedEmployeeId = value ?? '';
                          employee.text = selectedEmployeeId;
                        });
                      },
                    )
                  else
                    TextFormField(
                      key: const ValueKey('manager.review.employeeId'),
                      controller: employee,
                      decoration:
                          const InputDecoration(labelText: 'Employee ID'),
                      readOnly: existing != null,
                      validator: _required,
                    ),
                  const SizedBox(height: 12),
                  if (existing == null && cycles.isNotEmpty)
                    DropdownButtonFormField<String>(
                      key: const ValueKey('manager.review.cycle.dropdown'),
                      initialValue: selectedCycleId,
                      decoration:
                          const InputDecoration(labelText: 'Review cycle'),
                      items: [
                        for (final item in cycles)
                          DropdownMenuItem(
                            value: item.id,
                            child: Text(item.name),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedCycleId = value ?? '';
                          cycle.text = selectedCycleId;
                        });
                      },
                    )
                  else
                    TextFormField(
                      key: const ValueKey('manager.review.cycleId'),
                      controller: cycle,
                      decoration:
                          const InputDecoration(labelText: 'Review cycle ID'),
                      readOnly: existing != null,
                      validator: _required,
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey('manager.review.summary'),
                    controller: summary,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: 'Summary'),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey('manager.review.rating'),
                    controller: rating,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Rating optional',
                      hintText: '1-5',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const ValueKey('manager.review.save'),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final parsedRating = rating.text.trim().isEmpty
                    ? null
                    : double.tryParse(rating.text.trim());
                try {
                  final repo = ref.read(managerRepositoryProvider);
                  if (existing == null) {
                    await repo.submitReview(
                      employeeId: employee.text,
                      reviewCycleId: cycle.text,
                      summary: summary.text,
                      rating: parsedRating,
                    );
                  } else {
                    await repo.updateReview(
                      existing.id,
                      summary: summary.text,
                      rating: parsedRating,
                    );
                  }
                  _refresh(ref);
                  if (existing != null) {
                    ref.invalidate(managerReviewProvider(existing.id));
                  }
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    showManagerSuccessSnack(
                      context,
                      existing == null
                          ? 'Review submitted.'
                          : 'Review updated.',
                    );
                  }
                } catch (error) {
                  if (context.mounted) showManagerFailureSnack(context, error);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  } finally {
    employee.dispose();
    cycle.dispose();
    summary.dispose();
    rating.dispose();
  }
}

Future<void> _showStatusSheet(
  BuildContext context,
  WidgetRef ref,
  ManagerPerformanceReview review,
) async {
  var status = review.status;
  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Update review status'),
        content: DropdownButtonFormField<String>(
          key: const ValueKey('manager.review.status.dropdown'),
          initialValue: status,
          decoration: const InputDecoration(labelText: 'Status'),
          items: [
            for (final item in _reviewStatuses)
              DropdownMenuItem(value: item, child: Text(titleCase(item))),
          ],
          onChanged: (value) => setState(() => status = value ?? review.status),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const ValueKey('manager.review.status.save'),
            onPressed: () async {
              try {
                await ref.read(managerRepositoryProvider).updateReviewStatus(
                      review.id,
                      status: status,
                    );
                _refresh(ref);
                ref.invalidate(managerReviewProvider(review.id));
                if (context.mounted) {
                  Navigator.of(context).pop();
                  showManagerSuccessSnack(context, 'Review status updated.');
                }
              } catch (error) {
                if (context.mounted) showManagerFailureSnack(context, error);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

List<ManagerReviewCycle> _cyclesFromReviews(
  List<ManagerPerformanceReview> reviews,
) {
  final cycles = <String, ManagerReviewCycle>{};
  for (final review in reviews) {
    final cycle = review.reviewCycle;
    if (cycle != null) cycles[cycle.id] = cycle;
  }
  final sorted = cycles.values.toList(growable: false)
    ..sort((left, right) => left.name.compareTo(right.name));
  return sorted;
}

void _refresh(WidgetRef ref) {
  ref.invalidate(managerReviewsProvider);
  ref.invalidate(managerPerformanceReportProvider);
  ref.invalidate(managerTeamMembersProvider);
}

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'Required' : null;
