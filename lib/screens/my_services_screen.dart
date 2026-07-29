import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_request_models.dart';
import '../providers/service_request_providers.dart';
import '../theme/app_theme.dart';
import 'service_request_detail_screen.dart';

// Helper to get priority color
Color _getPriorityColor(String priority) {
  switch (priority.toUpperCase()) {
    case 'LOW':
      return Colors.grey;
    case 'URGENT':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

// Helper to get status colors and text
class _StatusConfig {
  final Color baseColor;
  final IconData icon;
  final String text;

  _StatusConfig(this.baseColor, this.icon, this.text);
}

_StatusConfig _getStatusConfig(String rawStatus) {
  final label = customerStatusLabel(rawStatus);
  
  if (label.contains('Assigned') || label.contains('Appointment') || label.contains('Way') || label.contains('Arrived')) {
    return _StatusConfig(const Color(0xFF3B82F6), Icons.person_outline, label);
  }
  if (label.contains('Progress') || label.contains('Started') || label.contains('Estimate') || label == 'On Hold' || label.contains('Waiting') || label.contains('Approval') || label.contains('Needed')) {
    return _StatusConfig(const Color(0xFFF59E0B), Icons.update, label);
  }
  if (label.contains('Completed') || label == 'Closed' || label.contains('Paid')) {
    return _StatusConfig(const Color(0xFF10B981), Icons.check_circle_outline, label);
  }
  if (label.contains('Cancel') || label.contains('Reject')) {
    return _StatusConfig(const Color(0xFFEF4444), Icons.cancel_outlined, label);
  }
  // Default fallback for "Request Received" or anything else
  return _StatusConfig(const Color(0xFF6B7280), Icons.info_outline, label);
}

// Helper to get left box icon and color based on status
(Color, IconData) _getCardTypeConfig(String rawStatus) {
  final label = customerStatusLabel(rawStatus);
  
  if (label.contains('Completed') || label == 'Closed' || label.contains('Paid')) {
    return (const Color(0xFF10B981), Icons.check_circle_outline);
  }
  if (label.contains('Cancel') || label.contains('Reject')) {
    return (const Color(0xFFEF4444), Icons.cancel_outlined);
  }
  if (label.contains('Progress') || label.contains('Started') || label.contains('Estimate') || label.contains('Waiting') || label == 'On Hold') {
    return (const Color(0xFFF59E0B), Icons.build);
  }
  // Default for New / Assigned
  return (const Color(0xFF10B981), Icons.build);
}

class MyServicesScreen extends ConsumerWidget {
  const MyServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(myServiceRequestsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('My Services', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.black)),
                          const SizedBox(height: 6),
                          Text('Track and manage your service requests', style: TextStyle(fontSize: 14, color: AppColors.neutral500)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0FDF4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.tune, color: Color(0xFF16A34A), size: 24),
                    ),
                  ],
                ),
              ),

              // Tab Bar Container
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2))],
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: const Color(0xFF16A34A),
                  unselectedLabelColor: AppColors.neutral500,
                  indicatorColor: const Color(0xFF16A34A),
                  indicatorWeight: 3,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Active', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 18),
                          SizedBox(width: 8),
                          Text('History', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tab Views
              Expanded(
                child: requests.when(
                  data: (items) {
                    final active = items.where((r) => r.isActive).toList();
                    final history = items.where((r) => !r.isActive).toList();
                    return TabBarView(
                      children: [
                        _RequestList(items: active, emptyMessage: 'No active service requests right now.'),
                        _RequestList(items: history, emptyMessage: 'No past service requests yet.'),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Failed to load your service requests: $err')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestList extends StatelessWidget {
  final List<ServiceRequestSummary> items;
  final String emptyMessage;
  const _RequestList({required this.items, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.checklist_rtl, color: AppColors.neutral200, size: 44),
            const SizedBox(height: 12),
            Text(emptyMessage, style: const TextStyle(color: AppColors.neutral500)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final r = items[index];
        final statusConf = _getStatusConfig(r.status);
        final cardConf = _getCardTypeConfig(r.status);
        final dateStr = DateTime.tryParse(r.createdAt)?.toLocal().toString().split(' ').first ?? '';

        return Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ServiceRequestDetailScreen(requestId: r.id))),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.04)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon Box with Dot
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: cardConf.$1.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(cardConf.$2, color: cardConf.$1, size: 22),
                      ),
                      Positioned(
                        top: -3,
                        left: -3,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: cardConf.$1, shape: BoxShape.circle),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.number, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppColors.black)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: _getPriorityColor(r.priority), shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text('${r.priority} priority', style: const TextStyle(color: AppColors.neutral500, fontSize: 11, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, color: AppColors.neutral500, size: 12),
                            const SizedBox(width: 6),
                            Text(dateStr, style: const TextStyle(color: AppColors.neutral500, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Pill Badge and Chevron
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusConf.baseColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusConf.icon, color: statusConf.baseColor, size: 12),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                statusConf.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: statusConf.baseColor, fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.neutral500, size: 18),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
