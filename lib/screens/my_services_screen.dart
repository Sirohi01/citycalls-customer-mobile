import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_request_models.dart';
import '../providers/service_request_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';
import 'service_request_detail_screen.dart';

// Per docs/rohit/05-customer-app-screen-list.md "Tracking" — Service Request
// List (active + history tabs). Detail drill-down (status timeline, live map,
// technician info) lives in service_request_detail_screen.dart.
class MyServicesScreen extends ConsumerWidget {
  const MyServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(myServiceRequestsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.neutral100,
        appBar: AppBar(
          title: const Text('My Services'),
          centerTitle: false,
          backgroundColor: AppColors.neutral100,
          surfaceTintColor: AppColors.neutral100,
          bottom: TabBar(
            labelColor: AppColors.black,
            unselectedLabelColor: AppColors.neutral500,
            indicatorColor: Theme.of(context).colorScheme.primary,
            indicatorWeight: 3,
            tabs: const [Tab(text: 'Active'), Tab(text: 'History')],
          ),
        ),
        body: requests.when(
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
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final r = items[index];
        final color = StatusBadge.colorFor(r.status);
        return Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.05),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ServiceRequestDetailScreen(requestId: r.id))),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.build_circle_outlined, color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.number, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                        const SizedBox(height: 3),
                        Text(
                          r.serviceName ?? '${r.priority} priority',
                          style: const TextStyle(color: AppColors.neutral500, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateTime.tryParse(r.createdAt)?.toLocal().toString().split(' ').first ?? '',
                          style: const TextStyle(color: AppColors.neutral500, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  StatusBadge(status: r.status),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
