import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_request_models.dart';
import '../providers/service_request_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';
import 'service_request_detail_screen.dart';

// Per docs/rohit/05-customer-app-screen-list.md "Tracking" — Service Request
// List (active + history tabs). Detail drill-down (status timeline, live map,
// technician info) is a separate, larger screen not built yet.
class MyServicesScreen extends ConsumerWidget {
  const MyServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(myServiceRequestsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          title: const Text('My Services'),
          centerTitle: false,
          bottom: const TabBar(
            labelColor: AppColors.black,
            unselectedLabelColor: AppColors.neutral500,
            indicatorColor: AppColors.black,
            tabs: [Tab(text: 'Active'), Tab(text: 'History')],
          ),
        ),
        body: requests.when(
          data: (items) {
            final active = items.where((r) => r.isActive).toList();
            final history = items.where((r) => !r.isActive).toList();
            return TabBarView(
              children: [
                _RequestList(items: active, emptyMessage: 'No active service requests.'),
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
      return Center(child: Text(emptyMessage, style: const TextStyle(color: AppColors.neutral500)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final r = items[index];
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ServiceRequestDetailScreen(requestId: r.id))),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(border: Border.all(color: AppColors.neutral200), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.number, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        '${r.priority} priority · ${DateTime.tryParse(r.createdAt)?.toLocal().toString().split(' ').first ?? ''}',
                        style: const TextStyle(color: AppColors.neutral500, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: r.status),
              ],
            ),
          ),
        );
      },
    );
  }
}
