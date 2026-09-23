import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/catalog_providers.dart';
import '../providers/customer_providers.dart';
import '../models/catalog_models.dart';
import '../widgets/media_gallery.dart';
import '../models/booking_models.dart';
import 'booking/product_select_screen.dart';
import '../widgets/state_views.dart';

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
  bool _pinFromSavedAddress = false;

  @override
  void initState() {
    super.initState();
    _prefillFromSavedAddress();
  }

  // A customer who already has a saved address shouldn't have to type its
  // PIN code in by hand — that's also what avoids the mismatch where
  // coverage gets checked for one PIN but the booking flow's Address Select
  // screen (next step) ends up using a different saved address entirely.
  // Best-effort: if this fails or there's no saved address, the field just
  // stays empty and manual entry still works exactly as before.
  Future<void> _prefillFromSavedAddress() async {
    try {
      final customer = await ref.read(myProfileProvider.future);
      if (customer.addresses.isEmpty || !mounted) return;
      final primary = customer.addresses.firstWhere((a) => a.isDefault, orElse: () => customer.addresses.first);
      setState(() {
        _pinCodeController.text = primary.pinCode;
        _pinFromSavedAddress = true;
      });
      _checkCoverage();
    } catch (_) {
      // Best-effort — profile fetch failing here shouldn't block the page.
    }
  }

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
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          // Background Gradient matching the UI
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 350,
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
            child: Column(
              children: [
                // --- Custom Header ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
                    ),
                  ),
                  const Text(
                    'Service Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.favorite_border, color: Color(0xFF16A34A), size: 20),
                    ),
                  ),
                ],
              ),
            ),
            
            // --- Body Content ---
            Expanded(
              child: service.when(
                data: (s) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Image Gallery Section ---
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        alignment: Alignment.topCenter,
                        child: media.when(
                          data: (files) => Stack(
                            children: [
                              MediaGallerySection(
                                media: files,
                                resolveUrl: catalogRepo.resolveMediaUrl,
                              ),
                              // Badge Overlay: Verified Experts
                              Positioned(
                                bottom: 35, // Moved up
                                left: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.06),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          _buildAvatar(),
                                          const SizedBox(width: 4),
                                          _buildAvatar(),
                                          const SizedBox(width: 4),
                                          _buildAvatar(),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF16A34A),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.check, color: Colors.white, size: 12),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Verified Experts',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Category/Snowflake Icon Overlay
                              Positioned(
                                bottom: 35, // Moved up
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.06),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    s.name.toLowerCase().contains('ac') ? Icons.ac_unit_rounded : Icons.home_repair_service,
                                    color: const Color(0xFF3B82F6),
                                    size: 28,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          loading: () => const SizedBox(
                              height: 200,
                              child: Center(child: CircularProgressIndicator())),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // --- Title ---
                      Text(
                        s.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // --- Stats Row Card ---
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem(
                              icon: Icons.currency_rupee_rounded,
                              iconColor: const Color(0xFF16A34A),
                              bgColor: const Color(0xFFF0FDF4),
                              title: '₹${s.pricing.basePrice.toStringAsFixed(0)}',
                              subtitle: 'Starting at',
                            ),
                            Container(width: 1, height: 40, color: Colors.grey.shade200),
                            _buildStatItem(
                              icon: Icons.schedule_rounded,
                              iconColor: const Color(0xFF3B82F6),
                              bgColor: const Color(0xFFEFF6FF),
                              title: '~${s.expectedDurationMinutes} min',
                              subtitle: 'Duration',
                            ),
                            Container(width: 1, height: 40, color: Colors.grey.shade200),
                            _buildStatItem(
                              icon: Icons.directions_car_rounded,
                              iconColor: const Color(0xFFF97316),
                              bgColor: const Color(0xFFFFF7ED),
                              title: '₹${s.pricing.visitingCharge.toStringAsFixed(0)}',
                              subtitle: 'Visiting charge',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // --- Service Description Card ---
                      if (s.description != null && s.description!.trim().isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6FAF6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFD1E8D5)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF16A34A).withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.description_outlined, color: Color(0xFF16A34A), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Service Description',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      s.description!,
                                      style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // --- Check Availability Card ---
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF0FDF4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.location_on, color: Color(0xFF16A34A), size: 18),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Check availability in your area',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text('PIN code', style: TextStyle(color: Colors.black54, fontSize: 12)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: TextField(
                                      controller: _pinCodeController,
                                      keyboardType: TextInputType.number,
                                      maxLength: 6,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        counterText: '',
                                      ),
                                      onChanged: (_) {
                                        if (_pinFromSavedAddress) setState(() => _pinFromSavedAddress = false);
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: _checking ? null : _checkCoverage,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    height: 48,
                                    width: 100,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16A34A),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: _checking
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Text(
                                            'Check',
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                            if (_pinFromSavedAddress) ...[
                              const SizedBox(height: 12),
                              const Text(
                                'Using your saved address — edit above to check a different area.',
                                style: TextStyle(color: Colors.black54, fontSize: 11),
                              ),
                            ],
                            if (_checkError != null) ...[
                              const SizedBox(height: 12),
                              Text(_checkError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                            ],
                            if (_coverage != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _coverage!.serviceable ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      _coverage!.serviceable ? Icons.check_circle_outline : Icons.error_outline,
                                      color: _coverage!.serviceable ? const Color(0xFF16A34A) : Colors.red,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _coverage!.serviceable
                                            ? 'Great news — this service is available in your area!'
                                            : 'Sorry, this service isn\'t available in your area yet — ${_coverageReasonLabel(_coverage!.reason)}',
                                        style: TextStyle(
                                          color: _coverage!.serviceable ? const Color(0xFF16A34A) : Colors.red,
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: AppErrorView(
                    error: err,
                    onRetry: () => ref.invalidate(serviceDetailProvider(widget.serviceId)),
                  ),
                ),
              ),
            ),

            // --- Sticky Bottom Action ---
            if (service.hasValue)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: _coverage?.serviceable == true
                      ? () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ProductSelectScreen(
                              draft: BookingDraft(
                                  serviceId: widget.serviceId,
                                  serviceName: service.value!.name,
                                  pinCode: _pinCodeController.text.trim()),
                            ),
                          ))
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: _coverage?.serviceable == true ? const Color(0xFF16A34A) : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_month_outlined, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'Book Now',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
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

  Widget _buildAvatar() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        color: Colors.grey.shade200,
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.person, size: 14, color: Colors.black38),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.black54, fontSize: 11),
        ),
      ],
    );
  }
}

// Mirrors catalog.service.ts's checkCoverage() reason codes — shown raw
// before this (e.g. "PIN_CODE_NOT_SERVICEABLE") reads as a bug, not a real
// coverage message.
String _coverageReasonLabel(String? reason) {
  switch (reason) {
    case 'PIN_CODE_NOT_SERVICEABLE':
      return 'we don\'t currently service this area';
    case 'SERVICE_NOT_ACTIVE':
      return 'this service isn\'t currently available';
    default:
      return 'please try a different PIN code';
  }
}
