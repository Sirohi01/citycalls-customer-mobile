import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Shared loading/error/empty presentation, per
// docs/rohit/11-loading-error-empty-states.md. Screens used to swallow errors
// with `error: (_, __) => const SizedBox.shrink()`, which rendered a blank
// area and gave the user nothing to act on — the customer app is explicitly
// NOT offline-first (docs/manish/08 §5), so a failed fetch has to say so and
// offer a retry rather than queue silently.

bool _isOffline(Object error) {
  if (error is! DioException) return false;
  return error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout;
}

String describeError(Object error) {
  if (_isOffline(error)) {
    return "You're offline. Check your connection and try again.";
  }
  if (error is DioException) {
    final body = error.response?.data;
    if (body is Map && body['message'] is String) return body['message'] as String;
    if (error.response?.statusCode == 403) {
      return "You don't have access to this.";
    }
    if (error.response?.statusCode == 404) return 'Not found.';
  }
  return 'Something went wrong. Please try again.';
}

class AppErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  final bool compact;

  const AppErrorView({super.key, required this.error, this.onRetry, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final offline = _isOffline(error);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: compact ? 16 : 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            offline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
            size: compact ? 28 : 40,
            color: AppColors.neutral500,
          ),
          SizedBox(height: compact ? 8 : 14),
          Text(
            describeError(error),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.neutral500,
              fontSize: compact ? 12.5 : 14,
              height: 1.4,
            ),
          ),
          if (onRetry != null) ...[
            SizedBox(height: compact ? 8 : 14),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF16A34A)),
            ),
          ],
        ],
      ),
    );
  }
}

class AppEmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const AppEmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(color: AppColors.neutral100, shape: BoxShape.circle),
            child: Icon(icon, size: 32, color: AppColors.neutral500),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.neutral500, height: 1.4),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    );
  }
}
