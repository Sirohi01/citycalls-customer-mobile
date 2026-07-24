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
                Text(s.name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                if (s.description != null && s.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(s.description!,
                      style: const TextStyle(
                          color: AppColors.neutral500, fontSize: 14, height: 1.4)),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      border: Border.all(color: AppColors.neutral200),
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      _detailRow('Starting price',
                          '₹${s.pricing.basePrice.toStringAsFixed(0)}'),
                      _detailRow('Visiting charge',
                          '₹${s.pricing.visitingCharge.toStringAsFixed(0)}'),
                      _detailRow('Estimated duration',
                          '~${s.expectedDurationMinutes} minutes'),
                      if (s.warrantyPeriodDays > 0)
                        _detailRow('Warranty', '${s.warrantyPeriodDays} days'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Check availability in your area',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
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
                      child: _checking
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Check'),
                    ),
                  ],
                ),
                if (_checkError != null)
                  Text(_checkError!, style: const TextStyle(color: Colors.red)),
                if (_coverage != null)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _coverage!.serviceable
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _coverage!.serviceable
                          ? 'Great news — this service is available in your area!'
                          : 'Sorry, this service isn\'t available in your area yet (${_coverage!.reason}).',
                      style: TextStyle(
                          color: _coverage!.serviceable
                              ? Colors.green.shade800
                              : Colors.red.shade800),
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton(
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
                  child: const Text('Book Now'),
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load service: $err')),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.neutral500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
