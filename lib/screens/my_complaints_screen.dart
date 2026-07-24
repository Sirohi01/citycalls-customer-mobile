import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/complaint_models.dart';
import '../providers/complaint_providers.dart';
import '../theme/app_theme.dart';
import 'raise_complaint_screen.dart';

class MyComplaintsScreen extends ConsumerWidget {
  const MyComplaintsScreen({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'OPEN':
        return Colors.orange;
      case 'IN_PROGRESS':
        return Colors.blue;
      case 'RESOLVED':
      case 'CLOSED':
        return Colors.green;
      default:
        return AppColors.neutral500;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaints = ref.watch(myComplaintsProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('My Complaints'), centerTitle: false),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RaiseComplaintScreen())),
        label: const Text('Raise Complaint'),
        icon: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myComplaintsProvider),
        child: complaints.when(
          data: (items) => items.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 120),
                    Icon(Icons.forum_outlined, color: AppColors.neutral200, size: 48),
                    SizedBox(height: 12),
                    Center(child: Text('No complaints raised yet.', style: TextStyle(color: AppColors.neutral500))),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _ComplaintCard(complaint: items[i], color: _statusColor(items[i].status)),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Failed to load complaints: $err')),
        ),
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final ComplaintSummary complaint;
  final Color color;
  const _ComplaintCard({required this.complaint, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(border: Border.all(color: AppColors.neutral200), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(complaint.subject, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(complaintStatusLabel(complaint.status), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(complaint.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.neutral500, fontSize: 13)),
          if (complaint.serviceRequestNumber != null) ...[
            const SizedBox(height: 6),
            Text('Re: ${complaint.serviceRequestNumber}', style: const TextStyle(color: AppColors.neutral500, fontSize: 11.5)),
          ],
          if (complaint.response != null && complaint.response!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.neutral100, borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Response from our team', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5)),
                  const SizedBox(height: 4),
                  Text(complaint.response!, style: const TextStyle(fontSize: 12.5)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            DateTime.tryParse(complaint.createdAt)?.toLocal().toString().split(' ').first ?? '',
            style: const TextStyle(color: AppColors.neutral500, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
