import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/states.dart';
import 'employee_models.dart';
import 'employee_repository.dart';
import 'widgets/employee_widgets.dart';

class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(reviewsProvider);

    return EmployeePage(
      title: 'Reviews',
      subtitle: 'Your performance reviews',
      action: IconButton.outlined(
        tooltip: 'Refresh',
        onPressed: () => ref.invalidate(reviewsProvider),
        icon: const Icon(Icons.refresh),
      ),
      child: reviews.when(
        loading: () => const LoadingState(label: 'Loading reviews...'),
        error: (error, _) => employeeErrorView(
          error,
          () => ref.invalidate(reviewsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.rate_review_outlined,
              title: 'No reviews yet',
              message: 'Submitted performance reviews will appear here.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(reviewsProvider);
              await ref.read(reviewsProvider.future);
            },
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final review = items[index];
                return SectionCard(
                  child: InkWell(
                    onTap: () => _showReviewDetails(context, review),
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
                            StatusChip(label: review.status),
                          ],
                        ),
                        const Divider(height: 24),
                        InfoLine(
                          label: 'Rating',
                          value: review.rating == null
                              ? 'Not rated'
                              : review.rating!.toStringAsFixed(1),
                        ),
                        InfoLine(
                          label: 'Submitted',
                          value: shortDateTime(review.submittedAt),
                        ),
                        InfoLine(
                          label: 'Cycle',
                          value: review.reviewCycle == null
                              ? review.reviewCycleId
                              : '${shortDate(review.reviewCycle!.startDate)} - ${shortDate(review.reviewCycle!.endDate)}',
                        ),
                      ],
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

  Future<void> _showReviewDetails(
    BuildContext context,
    PerformanceReviewItem review,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        final bottom = MediaQuery.viewInsetsOf(context).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(review.title,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                StatusChip(label: review.status),
                const SizedBox(height: 16),
                InfoLine(
                  label: 'Rating',
                  value: review.rating == null
                      ? 'Not rated'
                      : review.rating!.toStringAsFixed(1),
                ),
                InfoLine(
                  label: 'Submitted',
                  value: shortDateTime(review.submittedAt),
                ),
                const Divider(height: 28),
                Text(
                  review.summary ?? 'No summary available.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
