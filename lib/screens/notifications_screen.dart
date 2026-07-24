import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_providers.dart';
import '../theme/app_theme.dart';

// Per docs/rohit/05-customer-app-screen-list.md "Profile" group — Notification
// Center. Backed by GET /notifications (self-scoped by recipientUserId,
// filtered to channel=IN_APP — see notification_repository.dart).
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(myNotificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.neutral100,
      appBar: AppBar(title: const Text('Notifications'), centerTitle: false, backgroundColor: AppColors.neutral100, surfaceTintColor: AppColors.neutral100),
      body: notifications.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_none, color: AppColors.neutral200, size: 48),
                  const SizedBox(height: 12),
                  const Text('No notifications yet.', style: TextStyle(color: AppColors.neutral500)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final n = items[index];
              final primary = Theme.of(context).colorScheme.primary;
              return Material(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                elevation: n.isRead ? 0.5 : 1.5,
                shadowColor: Colors.black.withValues(alpha: n.isRead ? 0.03 : 0.06),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: n.isRead ? null : () => ref.read(notificationActionsProvider).markRead(n.id),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: n.isRead ? null : Border.all(color: primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: n.isRead ? AppColors.neutral100 : primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.notifications_outlined, size: 18, color: n.isRead ? AppColors.neutral500 : primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (n.subject != null) ...[
                                Text(n.subject!, style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                              ],
                              Text(n.body, style: const TextStyle(fontSize: 13.5, color: AppColors.neutral900)),
                              const SizedBox(height: 6),
                              Text(
                                DateTime.tryParse(n.createdAt)?.toLocal().toString().split('.').first ?? '',
                                style: const TextStyle(fontSize: 11, color: AppColors.neutral500),
                              ),
                            ],
                          ),
                        ),
                        if (!n.isRead) Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4), decoration: BoxDecoration(shape: BoxShape.circle, color: primary)),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load notifications: $err')),
      ),
    );
  }
}
