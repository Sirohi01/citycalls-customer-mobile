import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/visit_models.dart';
import '../providers/auth_providers.dart';
import '../providers/service_request_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/state_views.dart';

// The technician's field record for a request — diagnosis, parts fitted,
// work notes and before/after photos, written by citycalls-vendor-mobile and
// read here. Until this screen existed the customer could be billed for parts
// they had no way of seeing recorded anywhere.
//
// Readable because a CUSTOMER role holds fieldExecution:view at OWN scope
// (citycalls-api scripts/seed.ts) — the writes stay technician-only.
class ServiceVisitsScreen extends ConsumerWidget {
  final String requestId;
  final String? requestNumber;
  const ServiceVisitsScreen({super.key, required this.requestId, this.requestNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visits = ref.watch(serviceVisitsProvider(requestId));

    return Scaffold(
      backgroundColor: AppColors.neutral100,
      appBar: AppBar(
        title: const Text('Work Details'),
        centerTitle: false,
        bottom: requestNumber == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(22),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 10),
                    child: Text(
                      requestNumber!,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.neutral500),
                    ),
                  ),
                ),
              ),
      ),
      body: visits.when(
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyView(
              icon: Icons.engineering_outlined,
              title: 'No visit recorded yet',
              subtitle:
                  'Once a technician checks in and records the diagnosis, the full job card will appear here.',
            );
          }
          return RefreshIndicator(
            color: const Color(0xFF16A34A),
            onRefresh: () async => ref.invalidate(serviceVisitsProvider(requestId)),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, i) => _VisitCard(visit: items[i], totalVisits: items.length),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF16A34A))),
        error: (err, _) => Center(
          child: AppErrorView(
            error: err,
            onRetry: () => ref.invalidate(serviceVisitsProvider(requestId)),
          ),
        ),
      ),
    );
  }
}

class _VisitCard extends ConsumerWidget {
  final ServiceVisit visit;
  final int totalVisits;
  const _VisitCard({required this.visit, required this.totalVisits});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolveUrl = ref.read(apiClientProvider).resolveUrl;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          if (!visit.hasDetails) ...[
            const SizedBox(height: 12),
            const Text(
              'The technician has checked in. Diagnosis details will appear once recorded.',
              style: TextStyle(fontSize: 13, color: AppColors.neutral500, height: 1.4),
            ),
          ],
          if (!visit.inspection.isEmpty) ...[
            const SizedBox(height: 16),
            _sectionTitle(Icons.search_rounded, 'Diagnosis'),
            const SizedBox(height: 8),
            if (visit.inspection.defectFound != null)
              _labelledValue('Defect found', visit.inspection.defectFound!),
            if (visit.inspection.symptoms.isNotEmpty)
              _labelledValue('Symptoms', visit.inspection.symptoms.join(', ')),
            if (visit.inspection.solutionType != null)
              _labelledValue('Solution', visit.inspection.solutionType!),
          ],
          if (visit.parts.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionTitle(Icons.settings_outlined, 'Parts used'),
            const SizedBox(height: 8),
            ...visit.parts.map(_partRow),
            const Divider(height: 20),
            _totalRow('Parts total', visit.partsTotal),
            if (visit.labourCharge != null) _totalRow('Labour', visit.labourCharge!),
          ] else if (visit.labourCharge != null) ...[
            const SizedBox(height: 16),
            _sectionTitle(Icons.handyman_outlined, 'Charges'),
            const SizedBox(height: 8),
            _totalRow('Labour', visit.labourCharge!),
          ],
          if (visit.workNotes != null && visit.workNotes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionTitle(Icons.notes_outlined, 'Work notes'),
            const SizedBox(height: 6),
            Text(visit.workNotes!, style: const TextStyle(fontSize: 13.5, height: 1.45)),
          ],
          if (visit.beforeImages.isNotEmpty || visit.afterImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionTitle(Icons.photo_library_outlined, 'Photos'),
            const SizedBox(height: 10),
            if (visit.beforeImages.isNotEmpty)
              _imageStrip('Before', visit.beforeImages.map(resolveUrl).toList()),
            if (visit.afterImages.isNotEmpty) ...[
              if (visit.beforeImages.isNotEmpty) const SizedBox(height: 12),
              _imageStrip('After', visit.afterImages.map(resolveUrl).toList()),
            ],
          ],
          if (visit.nextVisitDate != null) ...[
            const SizedBox(height: 16),
            _noticeRow(
              Icons.event_repeat_outlined,
              'Next visit scheduled for ${_formatDate(visit.nextVisitDate!)}',
              const Color(0xFF2563EB),
            ),
          ],
          // Only the proof TYPE — completionProof.value is a hashed OTP
          // server-side and is never shown.
          if (visit.completionProofType != null) ...[
            const SizedBox(height: 12),
            _noticeRow(
              Icons.verified_outlined,
              'Completion verified by ${_proofLabel(visit.completionProofType!)}',
              const Color(0xFF16A34A),
            ),
          ],
        ],
      ),
    );
  }

  Widget _header() {
    final completed = visit.isCompleted;
    final color = completed ? const Color(0xFF16A34A) : const Color(0xFFF59E0B);
    final timestamp = visit.completedAt ?? visit.arrivedAt ?? visit.startedAt;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(completed ? Icons.check_circle_outline : Icons.pending_outlined, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                totalVisits > 1 ? 'Visit ${visit.visitNumber}' : 'Technician visit',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              if (timestamp != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    _formatDateTime(timestamp),
                    style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(
            completed ? 'Completed' : 'In progress',
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.neutral500),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
        ),
      ],
    );
  }

  Widget _labelledValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.neutral500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.35)),
          ),
        ],
      ),
    );
  }

  Widget _partRow(VisitPart part) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(part.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
          Text(
            '${_qty(part.qty)} × ₹${part.unitPrice.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 12.5, color: AppColors.neutral500),
          ),
          const SizedBox(width: 12),
          Text(
            '₹${part.lineTotal.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.neutral500)),
          Text('₹${amount.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _imageStrip(String label, List<String> urls) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.neutral500, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: urls.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) => GestureDetector(
              onTap: () => _openViewer(context, urls, i),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  urls[i],
                  width: 84,
                  height: 84,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 84,
                    height: 84,
                    color: AppColors.neutral100,
                    child: const Icon(Icons.broken_image_outlined, color: AppColors.neutral500, size: 20),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openViewer(BuildContext context, List<String> urls, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PhotoViewerScreen(urls: urls, initialIndex: initialIndex),
      ),
    );
  }

  Widget _noticeRow(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12.5, color: color, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  static String _proofLabel(String type) {
    switch (type) {
      case 'OTP':
        return 'OTP';
      case 'SIGNATURE':
        return 'your signature';
      case 'APP_CONFIRMATION':
        return 'in-app confirmation';
      default:
        return type.toLowerCase().replaceAll('_', ' ');
    }
  }

  static String _qty(double qty) =>
      qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toString();

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _formatDateTime(DateTime d) {
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final period = d.hour < 12 ? 'AM' : 'PM';
    return '${_formatDate(d)} · $hour:${d.minute.toString().padLeft(2, '0')} $period';
  }
}

class _PhotoViewerScreen extends StatelessWidget {
  final List<String> urls;
  final int initialIndex;
  const _PhotoViewerScreen({required this.urls, required this.initialIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: urls.length,
        itemBuilder: (context, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: Image.network(
              urls[i],
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
            ),
          ),
        ),
      ),
    );
  }
}
