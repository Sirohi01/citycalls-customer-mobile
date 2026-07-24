import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/catalog_providers.dart';
import '../models/catalog_models.dart';
import '../theme/app_theme.dart';
import '../widgets/media_gallery.dart';
import '../models/booking_models.dart';
import 'booking/product_select_screen.dart';

// Per docs/rohit/05-customer-app-screen-list.md "Home" — Service Detail.
// The pin-code coverage check here is the same gate the Booking flow itself
// enforces server-side (docs/manish/08-customer-app-functional-plan.md §2) —
// showing it up front avoids a customer getting through several booking
// steps before finding out their area isn't covered.
class ServiceDetailScreen extends ConsumerStatefulWidget {
  final String serviceId;
  const ServiceDetailScreen({super.key, required this.serviceId});

  @override
  ConsumerState<ServiceDetailScreen> createState() =>
      _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends ConsumerState<ServiceDetailScreen> {
  final _pinCodeController = TextEditingController();
  CoverageResult? _coverage;
  bool _checking = false;
  String? _checkError;

  @override
  void dispose() {
    _pinCodeController.dispose();
    super.dispose();
  }

  Future<void> _checkCoverage() async {
    final pinCode = _pinCodeController.text.trim();
    if (pinCode.length < 6) return;
    setState(() {
      _checking = true;
      _checkError = null;
      _coverage = null;
    });
    try {
      final result = await ref
          .read(catalogRepositoryProvider)
          .checkCoverage(widget.serviceId, pinCode);
      setState(() => _coverage = result);
    } catch (e) {
      setState(() => _checkError = 'Could not check coverage: $e');
    } finally {
      setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(serviceDetailProvider(widget.serviceId));
    final media = ref.watch(serviceMediaProvider(widget.serviceId));
    final catalogRepo = ref.read(catalogRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Service Details'), centerTitle: false),
      body: service.when(
        data: (s) => Padding(
          padding: const EdgeInsets.all(20),
          // SingleChildScrollView+Column, not ListView — a plain scrollable
          // Column tolerates a resizing child better than ListView's
          // Sliver/Viewport machinery. That alone wasn't sufficient, though:
          // the media gallery below still jumps from a fixed-height loading
          // placeholder to a very different final height (0 with no media,
          // ~220 images-only, 400+ with videos too) in a single frame — and
          // when that jump lands while this screen's own MaterialPageRoute
          // push transition is still animating in, it's reproduced the
          // RenderBox "hasSize" assertion (not a one-off hot-reload
          // artifact — it recurred across fresh app launches). AnimatedSize
          // is the actual fix: its RenderObject is built to tolerate a
          // child's size changing frame-to-frame without breaking the
          // surrounding scrollable/transition's layout invariants, instead
          // of handing the parent an abrupt single-frame size change.
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.topCenter,
                  child: media.when(
                    data: (files) => MediaGallerySection(
                        media: files, resolveUrl: catalogRepo.resolveMediaUrl),
                    loading: () => const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator())),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 4),
                Text(s.name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold, height: 1.2)),
                if (s.description != null && s.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(s.description!,
                      style: const TextStyle(
                          color: AppColors.neutral500, fontSize: 14, height: 1.4)),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                        child: _StatTile(
                            icon: Icons.currency_rupee,
                            label: 'Starting at',
                            value: '₹${s.pricing.basePrice.toStringAsFixed(0)}')),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _StatTile(
                            icon: Icons.schedule,
                            label: 'Duration',
                            value: '~${s.expectedDurationMinutes} min')),
                    if (s.warrantyPeriodDays > 0) ...[
                      const SizedBox(width: 10),
                      Expanded(
                          child: _StatTile(
                              icon: Icons.verified_user_outlined,
                              label: 'Warranty',
                              value: '${s.warrantyPeriodDays}d')),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                      color: AppColors.neutral100,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_car_filled_outlined,
                          size: 16, color: AppColors.neutral500),
                      const SizedBox(width: 8),
                      Text('Visiting charge: ₹${s.pricing.visitingCharge.toStringAsFixed(0)}',
                          style: const TextStyle(color: AppColors.neutral500, fontSize: 12.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4)),
                    ],
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10)),
                            child: Icon(Icons.location_on_outlined,
                                size: 18, color: Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text('Check availability in your area',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _pinCodeController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              decoration: const InputDecoration(
                                  labelText: 'PIN code', counterText: ''),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: _checking ? null : _checkCoverage,
                            style: FilledButton.styleFrom(minimumSize: const Size(88, 48)),
                            child: _checking
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Text('Check'),
                          ),
                        ],
                      ),
                      if (_checkError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(_checkError!, style: const TextStyle(color: Colors.red)),
                        ),
                      if (_coverage != null)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _coverage!.serviceable
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _coverage!.serviceable
                                    ? Icons.check_circle
                                    : Icons.info_outline,
                                color: _coverage!.serviceable
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _coverage!.serviceable
                                      ? 'Great news — this service is available in your area!'
                                      : 'Sorry, this service isn\'t available in your area yet (${_coverage!.reason}).',
                                  style: TextStyle(
                                      color: _coverage!.serviceable
                                          ? Colors.green.shade800
                                          : Colors.red.shade800,
                                      fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _coverage?.serviceable == true
                      ? () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ProductSelectScreen(
                              draft: BookingDraft(
                                  serviceId: s.id,
                                  serviceName: s.name,
                                  pinCode: _pinCodeController.text.trim()),
                            ),
                          ))
                      : null,
                  icon: const Icon(Icons.calendar_month_outlined, size: 18),
                  label: const Text('Book Now'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load service: $err')),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(label, style: const TextStyle(color: AppColors.neutral500, fontSize: 10.5)),
        ],
      ),
    );
  }
}
