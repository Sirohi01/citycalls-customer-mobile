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
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Notifications'), centerTitle: false),
      body: notifications.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No notifications yet.', style: TextStyle(color: AppColors.neutral500)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final n = items[index];
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: n.isRead ? null : () => ref.read(notificationActionsProvider).markRead(n.id),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: n.isRead ? AppColors.white : AppColors.neutral100,
                    border: Border.all(color: AppColors.neutral200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!n.isRead)
                        const Padding(
                          padding: EdgeInsets.only(top: 5, right: 10),
                          child: CircleAvatar(radius: 4, backgroundColor: AppColors.black),
                        ),
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
                    ],
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
