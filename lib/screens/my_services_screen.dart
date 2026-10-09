import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_request_models.dart';
import '../providers/service_request_providers.dart';
import '../widgets/state_views.dart';
import '../widgets/status_badge.dart';
import '../widgets/ui_kit.dart';
import 'service_browse_screen.dart';
import 'service_request_detail_screen.dart';

// Bookings tab: the customer's service requests, split into Active and
// History, newest first.
class MyServicesScreen extends ConsumerWidget {
  const MyServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(myServiceRequestsProvider);
    final items = requests.valueOrNull ?? const <ServiceRequestSummary>[];
    final active = items.where((r) => r.isActive).toList();
    final history = items.where((r) => !r.isActive).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 20,
          title: const Text('My Bookings'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Container(
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: kInk,
                  unselectedLabelColor: kMuted,
                  labelStyle: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w700),
                  tabs: [
                    Tab(
                        text: requests.hasValue
                            ? 'Active (${active.length})'
                            : 'Active'),
                    Tab(
                        text: requests.hasValue
                            ? 'History (${history.length})'
                            : 'History'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: requests.when(
          data: (_) => TabBarView(
            children: [
              _RequestList(
                items: active,
                emptyIcon: Icons.event_available_rounded,
                emptyTitle: 'No active bookings',
                emptyMessage:
                    'Book a service and track the technician right here.',
                showBookCta: true,
              ),
              _RequestList(
                items: history,
                emptyIcon: Icons.history_rounded,
                emptyTitle: 'No past bookings yet',
                emptyMessage: 'Completed and cancelled bookings show up here.',
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: AppErrorView(
                error: err,
                onRetry: () => ref.invalidate(myServiceRequestsProvider)),
          ),
        ),
      ),
    );
  }
}

class _RequestList extends ConsumerWidget {
  final List<ServiceRequestSummary> items;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;
  final bool showBookCta;
  const _RequestList({
    required this.items,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMessage,
    this.showBookCta = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> refresh() async => ref.invalidate(myServiceRequestsProvider);

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.55,
              child: UiEmptyState(
                icon: emptyIcon,
                title: emptyTitle,
                message: emptyMessage,
                actionLabel: showBookCta ? 'Book a service' : null,
                onAction: showBookCta
                    ? () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ServiceBrowseScreen()))
                    : null,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _BookingCard(request: items[index]),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final ServiceRequestSummary request;
  const _BookingCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final r = request;
    final color = StatusBadge.colorFor(r.status);
    final urgent = r.priority.toUpperCase() == 'URGENT';

    return UiCard(
      padding: const EdgeInsets.all(14),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ServiceRequestDetailScreen(requestId: r.id))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UiIconTile(icon: Icons.home_repair_service_rounded, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.serviceName ?? 'Service request',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: kInk),
                    ),
                    const SizedBox(height: 3),
                    Text('Booking #${r.number}',
                        style: const TextStyle(fontSize: 12, color: kMuted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: kFaint),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 13, color: kFaint),
              const SizedBox(width: 6),
              Text('Booked on ${formatDisplayDate(r.createdAt)}',
                  style: const TextStyle(fontSize: 12, color: kMuted)),
              if (urgent) ...[
                const SizedBox(width: 8),
                const UiPill(
                    text: 'Urgent',
                    color: Color(0xFFDC2626),
                    icon: Icons.bolt_rounded),
              ],
              const Spacer(),
              Flexible(
                child:
                    UiPill(text: customerStatusLabel(r.status), color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
