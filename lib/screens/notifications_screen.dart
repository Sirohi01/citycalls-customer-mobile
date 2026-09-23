import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_providers.dart';
import '../models/notification_models.dart';
import '../widgets/state_views.dart';
import 'notification_preferences_screen.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Unread', 'Service', 'Payment', 'Invoice'];

  IconData _getIconForSubject(String? subject) {
    if (subject == null) return Icons.notifications;
    final lower = subject.toLowerCase();
    if (lower.contains('payment')) return Icons.credit_card;
    if (lower.contains('invoice')) return Icons.description_outlined;
    if (lower.contains('estimate')) return Icons.request_quote_outlined;
    if (lower.contains('complete')) return Icons.check_circle;
    if (lower.contains('technician')) return Icons.local_shipping_outlined;
    return Icons.notifications;
  }

  Color _getIconBgColorForSubject(String? subject) {
    if (subject == null) return const Color(0xFFE6F4EA);
    final lower = subject.toLowerCase();
    if (lower.contains('payment') || lower.contains('technician')) return const Color(0xFFE0F2FE);
    if (lower.contains('invoice')) return const Color(0xFFF3E8FF);
    if (lower.contains('estimate')) return const Color(0xFFFEF3C7);
    if (lower.contains('complete') || lower.contains('service')) return const Color(0xFFE6F4EA);
    return const Color(0xFFF3F4F6); // Grey default
  }

  Color _getIconColorForSubject(String? subject) {
    if (subject == null) return const Color(0xFF16A34A);
    final lower = subject.toLowerCase();
    if (lower.contains('payment') || lower.contains('technician')) return const Color(0xFF0284C7);
    if (lower.contains('invoice')) return const Color(0xFF9333EA);
    if (lower.contains('estimate')) return const Color(0xFFD97706);
    if (lower.contains('complete') || lower.contains('service')) return const Color(0xFF16A34A);
    return const Color(0xFF6B7280); // Grey default
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(myNotificationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          // Top Background Glow (like All Categories)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF6EAF6),
                    Color(0xFFECF1FD),
                    Color(0xFFFAFAFA),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
            // --- Custom Header ---
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 12),
              child: Row(
                children: [
                  if (Navigator.canPop(context))
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back, color: Color(0xFF16A34A), size: 20),
                        ),
                      ),
                    ),
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: const Icon(Icons.more_vert, color: Colors.black87, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // --- Filter Chips ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _selectedFilter = filter),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF16A34A) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // --- Main List ---
            Expanded(
              child: notificationsAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 40),
                        const AppEmptyView(
                          icon: Icons.notifications_none_rounded,
                          title: 'No notifications yet',
                          subtitle: "Updates about your bookings, estimates and payments will show up here.",
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildStayUpdatedCard(),
                        ),
                      ],
                    );
                  }

                  List<AppNotification> filteredItems = items;
                  if (_selectedFilter != 'All') {
                    if (_selectedFilter == 'Unread') {
                      filteredItems = items.where((n) => !n.isRead).toList();
                    } else if (_selectedFilter == 'Service') {
                      filteredItems = items.where((n) {
                        final lower = n.subject?.toLowerCase() ?? '';
                        return lower.contains('service') || lower.contains('technician') || lower.contains('complete');
                      }).toList();
                    } else if (_selectedFilter == 'Payment') {
                      filteredItems = items.where((n) => (n.subject?.toLowerCase() ?? '').contains('payment')).toList();
                    } else if (_selectedFilter == 'Invoice') {
                      filteredItems = items.where((n) {
                        final lower = n.subject?.toLowerCase() ?? '';
                        return lower.contains('invoice') || lower.contains('estimate');
                      }).toList();
                    }
                  }

                  if (filteredItems.isEmpty) {
                    return AppEmptyView(
                      icon: Icons.filter_list_off_rounded,
                      title: 'Nothing under "$_selectedFilter"',
                      subtitle: 'Try a different filter to see your other notifications.',
                    );
                  }

                  // Real data rendering (simplified grouping)
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text('Recent', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 12),
                      ...filteredItems.map((n) => _buildNotificationCard(n)),
                      const SizedBox(height: 12),
                      _buildStayUpdatedCard(),
                      const SizedBox(height: 32),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF16A34A))),
                error: (err, _) => ListView(
                  children: [
                    const SizedBox(height: 40),
                    AppErrorView(error: err, onRetry: () => ref.invalidate(myNotificationsProvider)),
                  ],
                ),
              ),
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: n.isRead ? Colors.white : const Color(0xFFF4FBF7), // Light green tint for unread
        borderRadius: BorderRadius.circular(16),
        border: n.isRead ? Border.all(color: Colors.transparent) : Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: n.isRead ? null : () => ref.read(notificationActionsProvider).markRead(n.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _getIconBgColorForSubject(n.subject),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getIconForSubject(n.subject), color: _getIconColorForSubject(n.subject), size: 22),
                ),
                const SizedBox(width: 14),
                // Texts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (n.subject != null) ...[
                        Text(
                          n.subject!,
                          style: TextStyle(
                            fontWeight: n.isRead ? FontWeight.w700 : FontWeight.w900,
                            fontSize: 13,
                            color: n.isRead ? Colors.black87 : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 3),
                      ],
                      Text(
                        n.body,
                        style: TextStyle(
                          fontSize: 12,
                          color: n.isRead ? Colors.black54 : Colors.black87,
                          fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        n.createdAt.replaceFirst('T', ' ').split('.').first,
                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Right side items (Dot and Arrow)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 4, bottom: 20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: n.isRead ? Colors.transparent : const Color(0xFF16A34A),
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Was a Switch bound to a local bool that persisted nothing and reached no
  // API — it looked like a working preference but wasn't one. Notification
  // channel consent genuinely lives on PATCH /customers/:id/consent, which is
  // what NotificationPreferencesScreen drives, so this now takes the user
  // there instead.
  Widget _buildStayUpdatedCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NotificationPreferencesScreen()),
      ),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5ED), // Light green to match the mockup
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_none, color: Color(0xFF16A34A), size: 26),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stay Updated', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black87)),
                SizedBox(height: 2),
                Text('Get instant alerts about your service, payment and more.', style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF16A34A), size: 22),
        ],
      ),
      ),
    );
  }
}
