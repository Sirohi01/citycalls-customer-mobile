import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/catalog_providers.dart';
import '../providers/customer_providers.dart';
import '../providers/favourites_providers.dart';
import '../providers/location_providers.dart';
import 'favourites_screen.dart';
import '../models/catalog_models.dart';
import '../models/customer_models.dart';
import '../widgets/media_gallery.dart';
import '../models/media_models.dart';
import 'home_screen.dart' show formatServiceDuration;
import '../models/booking_models.dart';
import 'booking/address_select_screen.dart';
import 'booking/product_select_screen.dart';
import '../widgets/state_views.dart';

class ServiceDetailScreen extends ConsumerStatefulWidget {
  final String serviceId;
  const ServiceDetailScreen({super.key, required this.serviceId});

  @override
  ConsumerState<ServiceDetailScreen> createState() =>
      _ServiceDetailScreenState();
}

// Where the PIN code being checked came from.
enum _PinSource { current, saved, manual }

class _ServiceDetailScreenState extends ConsumerState<ServiceDetailScreen> {
  final _pinCodeController = TextEditingController();
  CoverageResult? _coverage;
  bool _checking = false;
  String? _checkError;
  _PinSource _pinSource = _PinSource.manual;
  String? _savedAddressId;
  // Set once the customer picks a source or types a PIN themselves, so a
  // slow location lookup finishing afterwards can't overwrite their choice.
  bool _userPicked = false;

  @override
  void initState() {
    super.initState();
    _applyDefaultPin();
  }

  // Starts from where the customer is right now (the same current location the
  // home screen shows), and falls back to their default saved address when
  // location is off, denied, or has no PIN. Either way they can switch to
  // another saved address or type any PIN - see the chips in the card.
  // Best-effort: if both fail the field stays empty and manual entry works.
  Future<void> _applyDefaultPin() async {
    CurrentPlace? place;
    try {
      place = await ref
          .read(currentPlaceProvider.future)
          .timeout(const Duration(seconds: 4));
    } catch (_) {
      // Slow or failed lookup - fall through to the saved address.
    }
    if (!mounted || _userPicked) return;
    if (place != null && place.hasPin) {
      _useCurrent(place);
      return;
    }
    try {
      final customer = await ref.read(myProfileProvider.future);
      if (customer.addresses.isEmpty || !mounted || _userPicked) return;
      _useSaved(customer.addresses.firstWhere((a) => a.isDefault,
          orElse: () => customer.addresses.first));
    } catch (_) {
      // Best-effort - profile fetch failing here shouldn't block the page.
    }
  }

  void _useCurrent(CurrentPlace place) {
    setState(() {
      _pinCodeController.text = place.pinCode;
      _pinSource = _PinSource.current;
      _savedAddressId = null;
    });
    _checkCoverage();
  }

  void _useSaved(CustomerAddress address) {
    setState(() {
      _pinCodeController.text = address.pinCode;
      _pinSource = _PinSource.saved;
      _savedAddressId = address.id;
    });
    _checkCoverage();
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
    final files = media.valueOrNull ?? const <MediaFile>[];
    final imageUrls = files
        .where((f) => !f.isVideo)
        .map(catalogRepo.resolveMediaUrl)
        .toList();
    final videos = files.where((f) => f.isVideo).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Row(
                  children: [
                    _RoundButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Service Details',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    _FavouriteButton(serviceId: widget.serviceId),
                  ],
                ),
              ),
              Expanded(
                child: service.when(
                  data: (s) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HeroGallery(
                          service: s,
                          imageUrls: imageUrls,
                          loading: media.isLoading,
                        ),
                        const SizedBox(height: 18),
                        _buildHeader(s),
                        const SizedBox(height: 16),
                        _buildStats(s),
                        if (s.description != null &&
                            s.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const _SectionTitle('About this service'),
                          const SizedBox(height: 8),
                          _Card(
                            child: Text(
                              s.description!,
                              style: const TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 13.5,
                                height: 1.55,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        const _SectionTitle('Why book with CityCalls'),
                        const SizedBox(height: 8),
                        _buildAssurances(s),
                        const SizedBox(height: 20),
                        const _SectionTitle('Check availability'),
                        const SizedBox(height: 8),
                        _buildCoverageCard(),
                        if (videos.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          MediaGallerySection(
                            media: videos,
                            resolveUrl: catalogRepo.resolveMediaUrl,
                          ),
                        ],
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  loading: () => const Center(
                      child: CircularProgressIndicator(color: _kGreen)),
                  error: (err, _) => Center(
                    child: AppErrorView(
                      error: err,
                      onRetry: () => ref
                          .invalidate(serviceDetailProvider(widget.serviceId)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar:
            service.hasValue ? _buildBottomBar(service.value!) : null,
      ),
    );
  }

  Widget _buildHeader(Service s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            const _Chip(
              icon: Icons.verified_rounded,
              label: 'Verified Experts',
              color: _kGreen,
            ),
            if (s.warrantyPeriodDays > 0)
              _Chip(
                icon: Icons.shield_outlined,
                label: '${s.warrantyPeriodDays} days warranty',
                color: const Color(0xFF2563EB),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          s.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            height: 1.25,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${s.pricing.basePrice.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: _kGreen,
                height: 1,
              ),
            ),
            const SizedBox(width: 6),
            const Padding(
              padding: EdgeInsets.only(bottom: 2),
              child: Text(
                'starting price',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStats(Service s) {
    final tiles = <Widget>[
      _StatTile(
        icon: Icons.schedule_rounded,
        color: const Color(0xFF2563EB),
        value: formatServiceDuration(s.expectedDurationMinutes),
        label: 'Duration',
      ),
      if (s.pricing.visitingCharge > 0)
        _StatTile(
          icon: Icons.directions_car_rounded,
          color: const Color(0xFFF97316),
          value: '₹${s.pricing.visitingCharge.toStringAsFixed(0)}',
          label: 'Visiting charge',
        ),
      if (s.pricing.inspectionCharge > 0)
        _StatTile(
          icon: Icons.search_rounded,
          color: const Color(0xFF9333EA),
          value: '₹${s.pricing.inspectionCharge.toStringAsFixed(0)}',
          label: 'Inspection',
        ),
    ];
    return Row(
      children: [
        for (int i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }

  Widget _buildAssurances(Service s) {
    final items = [
      (
        Icons.verified_user_outlined,
        'Background-verified professionals',
        'Trained, ID-checked experts only'
      ),
      (
        Icons.receipt_long_outlined,
        'Transparent pricing',
        'No hidden charges, pay after service'
      ),
      (
        Icons.shield_outlined,
        s.warrantyPeriodDays > 0
            ? '${s.warrantyPeriodDays}-day service warranty'
            : 'Quality assured',
        'Free re-visit if the issue comes back'
      ),
    ];
    return _Card(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _kGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(items[i].$1, color: _kGreen, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[i].$2,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          items[i].$3,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // "Current location" first, then each saved address; typing a PIN is the
  // third way and clears the selection.
  Widget _buildPinSources() {
    final place = ref.watch(currentPlaceProvider).valueOrNull;
    final addresses =
        ref.watch(myProfileProvider).valueOrNull?.addresses ?? const [];
    final showCurrent = place != null && place.hasPin;
    if (!showCurrent && addresses.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (showCurrent)
            _SourceChip(
              icon: Icons.my_location_rounded,
              label: 'Current location',
              selected: _pinSource == _PinSource.current,
              onTap: () {
                _userPicked = true;
                _useCurrent(place);
              },
            ),
          for (final a in addresses)
            _SourceChip(
              icon: Icons.home_outlined,
              label: (a.label?.trim().isNotEmpty ?? false)
                  ? a.label!.trim()
                  : a.city,
              selected:
                  _pinSource == _PinSource.saved && _savedAddressId == a.id,
              onTap: () {
                _userPicked = true;
                _useSaved(a);
              },
            ),
        ],
      ),
    );
  }

  String? _pinSourceNote() {
    switch (_pinSource) {
      case _PinSource.current:
        final label = ref.read(currentPlaceProvider).valueOrNull?.label;
        return label == null
            ? 'Using your current location.'
            : 'Using your current location · $label';
      case _PinSource.saved:
        final a = ref
            .read(myProfileProvider)
            .valueOrNull
            ?.addresses
            .where((a) => a.id == _savedAddressId)
            .firstOrNull;
        final name =
            (a?.label?.trim().isNotEmpty ?? false) ? a!.label!.trim() : null;
        return name == null
            ? 'Using your saved address.'
            : 'Using your saved address · $name';
      case _PinSource.manual:
        return null;
    }
  }

  Widget _buildCoverageCard() {
    final coverage = _coverage;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Check if we serve your area - use where you are, a saved address, or another PIN code.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          _buildPinSources(),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _pinCodeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'PIN code',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                        color: Color(0xFF94A3B8),
                      ),
                      prefixIcon: Icon(Icons.location_on_outlined,
                          color: _kGreen, size: 18),
                      prefixIconConstraints:
                          BoxConstraints(minWidth: 38, minHeight: 38),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                      counterText: '',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _userPicked = true;
                        _pinSource = _PinSource.manual;
                        _savedAddressId = null;
                        _coverage = null;
                      });
                      if (value.trim().length == 6) _checkCoverage();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: _checking ? null : _checkCoverage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _kGreen.withValues(alpha: 0.6),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _checking
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Check',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13.5)),
                ),
              ),
            ],
          ),
          if (_pinSourceNote() case final note?) ...[
            const SizedBox(height: 8),
            Text(
              note,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
            ),
          ],
          if (_checkError != null) ...[
            const SizedBox(height: 10),
            Text(_checkError!,
                style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
          if (coverage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: coverage.serviceable
                    ? const Color(0xFFF0FDF4)
                    : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: coverage.serviceable
                      ? const Color(0xFFBBF7D0)
                      : const Color(0xFFFECACA),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    coverage.serviceable
                        ? Icons.check_circle_rounded
                        : Icons.error_rounded,
                    color: coverage.serviceable ? _kGreen : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      coverage.serviceable
                          ? 'Great news — this service is available in your area!'
                          : 'Sorry, this service isn\'t available in your area yet — ${_coverageReasonLabel(coverage.reason)}',
                      style: TextStyle(
                        color: coverage.serviceable
                            ? const Color(0xFF166534)
                            : const Color(0xFFB91C1C),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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
    );
  }

  // The "which appliance" step only makes sense for Home Appliances. Home
  // Cleaning, Pest Control, HelpNow and Salon bookings go straight to the
  // address step.
  Future<void> _startBooking(Service s) async {
    var needsAppliance = true;
    try {
      final categories = await ref.read(serviceCategoriesProvider.future);
      final label = categories
          .where((c) => c.id == s.categoryId)
          .map((c) => c.label.toLowerCase())
          .firstOrNull;
      // Unknown category (list failed or service points elsewhere) keeps the
      // old behaviour of asking, rather than silently dropping the step.
      if (label != null) needsAppliance = label.contains('appliance');
    } catch (_) {}
    if (!mounted) return;

    final draft = BookingDraft(
      serviceId: widget.serviceId,
      serviceName: s.name,
      pinCode: _pinCodeController.text.trim(),
      hasProductStep: needsAppliance,
      preferredAddressId:
          _pinSource == _PinSource.saved ? _savedAddressId : null,
      preferCurrentLocation: _pinSource == _PinSource.current,
    );
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => needsAppliance
          ? ProductSelectScreen(draft: draft)
          : AddressSelectScreen(draft: draft),
    ));
  }

  Widget _buildBottomBar(Service s) {
    final canBook = _coverage?.serviceable == true;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹${s.pricing.basePrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    canBook ? 'Starting price' : 'Check PIN code to book',
                    style: const TextStyle(
                        fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: canBook ? () => _startBooking(s) : null,
                    icon: const Icon(Icons.calendar_month_rounded, size: 16),
                    label: const Text(
                      'Book Now',
                      style: TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFCBD5E1),
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SourceChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _kGreen : const Color(0xFFE2E8F0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15, color: selected ? _kGreen : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected
                    ? const Color(0xFF166534)
                    : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _kGreen = Color(0xFF16A34A);
const _kBg = Color(0xFFF8FAFC);

// Photo carousel in a rounded card. Each photo fills the whole frame (cover,
// no empty margins) and the carousel auto-advances when there are several.
class _HeroGallery extends StatefulWidget {
  final Service service;
  final List<String> imageUrls;
  final bool loading;
  const _HeroGallery({
    required this.service,
    required this.imageUrls,
    required this.loading,
  });

  @override
  State<_HeroGallery> createState() => _HeroGalleryState();
}

class _HeroGalleryState extends State<_HeroGallery> {
  final _controller = PageController();
  int _index = 0;
  Timer? _timer;

  static const _autoScrollEvery = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  @override
  void didUpdateWidget(covariant _HeroGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Photos usually arrive after the first build (media loads separately).
    if (oldWidget.imageUrls.length != widget.imageUrls.length) _restartTimer();
  }

  // (Re)start auto-scroll; called again after a manual swipe so the next
  // automatic move waits a full interval.
  void _restartTimer() {
    _timer?.cancel();
    if (widget.imageUrls.length < 2) return;
    _timer = Timer.periodic(_autoScrollEvery, (_) {
      if (!_controller.hasClients) return;
      final next = (_index + 1) % widget.imageUrls.length;
      if (next == 0) {
        _controller.jumpToPage(0);
      } else {
        _controller.animateToPage(next,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.imageUrls;
    const fallback = Center(
      child: Icon(Icons.home_repair_service_rounded,
          color: Color(0xFF86EFAC), size: 72),
    );

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  urls.isEmpty
                      ? (widget.loading
                          ? const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: _kGreen),
                              ),
                            )
                          : fallback)
                      : PageView.builder(
                          controller: _controller,
                          itemCount: urls.length,
                          onPageChanged: (i) => setState(() => _index = i),
                          // Listener (not a GestureDetector) so it doesn't fight the
                          // PageView for the swipe; a touch resets the countdown.
                          itemBuilder: (_, i) => Listener(
                            onPointerDown: (_) => _restartTimer(),
                            child: _FullPhoto(url: urls[i], fallback: fallback),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
        if (urls.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(urls.length, (i) {
              final active = i == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? _kGreen : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(6),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

// Shows the entire photo (BoxFit.contain) so nothing is cropped, over a
// blurred, enlarged copy of itself so non-matching aspect ratios don't leave
// empty bars.
class _FullPhoto extends StatelessWidget {
  final String url;
  final Widget fallback;
  const _FullPhoto({required this.url, required this.fallback});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        Container(color: Colors.white.withValues(alpha: 0.25)),
        Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kGreen),
                  ),
                ),
          errorBuilder: (_, __, ___) => fallback,
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(side: BorderSide(color: Color(0xFFE2E8F0))),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, size: 20, color: const Color(0xFF0F172A)),
        ),
      ),
    );
  }
}

// Heart in the top bar: saves / removes this service from My Favourites.
class _FavouriteButton extends ConsumerWidget {
  final String serviceId;
  const _FavouriteButton({required this.serviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav =
        ref.watch(favouritesProvider).valueOrNull?.contains(serviceId) ?? false;
    return Material(
      color: isFav ? const Color(0xFFFEF2F2) : Colors.white,
      shape: CircleBorder(
        side: BorderSide(
            color: isFav ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () async {
          final messenger = ScaffoldMessenger.of(context);
          final navigator = Navigator.of(context);
          final added =
              await ref.read(favouritesProvider.notifier).toggle(serviceId);
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(
                  added ? 'Added to favourites' : 'Removed from favourites'),
              action: added
                  ? SnackBarAction(
                      label: 'View',
                      onPressed: () => navigator.push(MaterialPageRoute(
                          builder: (_) => const FavouritesScreen())),
                    )
                  : null,
            ));
        },
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey(isFav),
              size: 20,
              color: isFav ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _Card({required this.child, this.padding = const EdgeInsets.all(14)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: Color(0xFF0F172A),
        letterSpacing: -0.2,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _StatTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: 0.06), Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 15),
          ),
        ],
      ),
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
