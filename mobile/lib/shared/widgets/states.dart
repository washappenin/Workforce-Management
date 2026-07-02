import 'package:flutter/material.dart';

import '../../core/theme/aurelia_theme.dart';

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.label});
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(strokeWidth: 2),
          if (label != null) ...[
            const SizedBox(height: 16),
            Text(label!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
  });
  final String title;
  final String? message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _CenteredCard(
      icon: icon,
      title: title,
      message: message,
    );
  }
}

class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.actionLabel = 'Try again',
    this.icon = Icons.error_outline,
  });
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String actionLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _CenteredCard(
      icon: icon,
      title: title,
      message: message,
      action: onRetry == null
          ? null
          : OutlinedButton(onPressed: onRetry, child: Text(actionLabel)),
    );
  }
}

class AccessDeniedState extends StatelessWidget {
  const AccessDeniedState({super.key, this.message});
  final String? message;
  @override
  Widget build(BuildContext context) {
    return ErrorStateView(
      icon: Icons.lock_outline,
      title: 'Access denied',
      message: message ?? 'You do not have permission to view this page.',
    );
  }
}

class NotFoundState extends StatelessWidget {
  const NotFoundState({super.key, this.message});
  final String? message;
  @override
  Widget build(BuildContext context) {
    return ErrorStateView(
      icon: Icons.search_off,
      title: 'Not found',
      message: message ?? 'The page or resource you requested does not exist.',
    );
  }
}

class ConnectionErrorState extends StatelessWidget {
  const ConnectionErrorState({super.key, this.onRetry});
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) {
    return ErrorStateView(
      icon: Icons.wifi_off,
      title: 'Connection problem',
      message:
          'We could not reach the server. Check your connection and try again.',
      onRetry: onRetry,
    );
  }
}

class ExpiredSessionBanner extends StatelessWidget {
  const ExpiredSessionBanner({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AureliaColors.danger.withValues(alpha: 0.08),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AureliaColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your session expired. Please sign in again.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AureliaColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

class ValidationErrorList extends StatelessWidget {
  const ValidationErrorList({super.key, required this.errors});
  final Map<String, Object?> errors;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AureliaColors.danger.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AureliaColors.danger.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: errors.entries
            .map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '${e.key}: ${e.value}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AureliaColors.danger),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _CenteredCard extends StatelessWidget {
  const _CenteredCard({
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AureliaColors.muted),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
