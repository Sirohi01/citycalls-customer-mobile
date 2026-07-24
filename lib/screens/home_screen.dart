import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/customer_providers.dart';
import '../providers/service_request_providers.dart';
import '../providers/catalog_providers.dart';
import '../models/service_request_models.dart';
import '../models/catalog_models.dart';
import '../models/customer_models.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';
import '../widgets/glow_blob.dart';
import 'service_browse_screen.dart';
import 'service_request_detail_screen.dart';
import 'service_detail_screen.dart';
import 'my_services_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider);
    final requests = ref.watch(myServiceRequestsProvider);
    final categories = ref.watch(serviceCategoriesProvider);
    final popularServices = ref.watch(servicesByCategoryProvider(null));
    final activeCount = requests.maybeWhen(
        data: (items) => items.where((r) => r.isActive).length,
        orElse: () => 0);
    final completedCount = requests.maybeWhen(
      data: (items) =>
          items.where((r) => !r.isActive && r.status != 'CANCELLED').length,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: AppColors.neutral100,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myProfileProvider);
          ref.invalidate(myServiceRequestsProvider);
          ref.invalidate(serviceCategoriesProvider);
          ref.invalidate(servicesByCategoryProvider);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Stack + Positioned(bottom: negative) with clipBehavior: Clip.none
            // is the layout-safe way to float the CTA card across the
            // header/body seam — a negative Container margin trips
            // Container's margin.isNonNegative assertion instead. The Stack's
            // own box still ends flush at the header's bottom (Positioned
            // children don't affect that), so the SizedBox below has to
            // reserve enough room to clear the card's overflow plus breathing
            // space before the next section.
            Stack(
              clipBehavior: Clip.none,
              children: [
                _Header(
                  greeting: _greeting(),
                  profile: profile,
                  activeCount: activeCount,
                  completedCount: completedCount,
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: -34,
                  child: _BookServiceCard(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const ServiceBrowseScreen()))),
                ),
              ],
            ),
            const SizedBox(height: 56),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _LocationBar(
                  profile: profile,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const ProfileScreen()))),
            ),
            const SizedBox(height: 22),
            const _TrustStrip(),
            const SizedBox(height: 26),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Categories',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black)),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ServiceBrowseScreen())),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.neutral500,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero),
                    child: const Text('See all',
                        style: TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            categories.when(
              data: (cats) => cats.isEmpty
                  ? const SizedBox.shrink()
                  : SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: cats.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (context, i) => _CategoryQuickAccess(
                            category: cats[i], colorIndex: i),
                      ),
                    ),
              loading: () => const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Popular Services',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black)),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ServiceBrowseScreen())),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.neutral500,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero),
                    child: const Text('See all',
                        style: TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            popularServices.when(
              data: (items) => items.isEmpty
                  ? const SizedBox.shrink()
                  : SizedBox(
                      height: 190,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: items.length > 8 ? 8 : items.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (context, i) =>
                            _PopularServiceCard(service: items[i]),
                      ),
                    ),
              loading: () => const SizedBox(
                  height: 190,
                  child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox.shrink(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Active Requests',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black)),
                      if (activeCount > 0)
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const MyServicesScreen())),
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.neutral500,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero),
                          child: const Text('See all',
                              style: TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  requests.when(
                    data: (items) {
                      final active = items.where((r) => r.isActive).toList();
                      if (active.isEmpty) {
                        return _emptyCard(
                            'No active service requests right now.');
                      }
                      return Column(
                          children: active
                              .map((r) => _RequestCard(request: r))
                              .toList());
                    },
                    loading: () => const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator())),
                    error: (err, _) =>
                        _emptyCard('Failed to load your requests: $err'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: AppColors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(Icons.checklist_rtl, color: AppColors.neutral200, size: 36),
          const SizedBox(height: 10),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.neutral500)),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String greeting;
  final AsyncValue profile;
  final int activeCount;
  final int completedCount;
  const _Header(
      {required this.greeting,
      required this.profile,
      required this.activeCount,
      required this.completedCount});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 56),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.black, AppColors.neutral900],
          ),
        ),
        // The gradient itself stays full-bleed behind the status bar (that's
        // the point of not wrapping the whole Container in SafeArea) — only
        // the content inside is pushed clear of the notch/status bar, which
        // is what actually needed to move down, not the background.
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned(
                    right: -60,
                    top: -70,
                    child: GlowBlob(color: AppColors.lime500, size: 220)),
                const Positioned(
                    left: -70,
                    bottom: -40,
                    child: GlowBlob(color: AppColors.indigo500, size: 180)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        profile.when(
                          data: (customer) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(greeting,
                                  style: const TextStyle(
                                      color: AppColors.slate400, fontSize: 13)),
                              const SizedBox(height: 3),
                              Text(customer.name,
                                  style: const TextStyle(
                                      fontSize: 23,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ],
                          ),
                          loading: () => const SizedBox(height: 44),
                          error: (_, __) => const Text('Hi there',
                              style: TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const ProfileScreen())),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.lime400, width: 1.5)),
                            child: const CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.neutral900,
                                child: Icon(Icons.person_outline,
                                    color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                            child: _StatChip(
                                icon: Icons.bolt,
                                label: 'Active',
                                value: activeCount,
                                accent: AppColors.lime400)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _StatChip(
                                icon: Icons.task_alt,
                                label: 'Completed',
                                value: completedCount,
                                accent: AppColors.slate200)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color accent;
  const _StatChip(
      {required this.icon,
      required this.label,
      required this.value,
      required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$value',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      height: 1.1)),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.slate400, fontSize: 10.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookServiceCard extends StatelessWidget {
  final VoidCallback onTap;
  const _BookServiceCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                    color: AppColors.lime500, shape: BoxShape.circle),
                child: const Icon(Icons.add_circle_outline,
                    color: AppColors.black),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Book a Service',
                        style: TextStyle(
                            color: AppColors.black,
                            fontWeight: FontWeight.w700,
                            fontSize: 15.5)),
                    SizedBox(height: 2),
                    Text('Browse our full service catalog',
                        style: TextStyle(
                            color: AppColors.neutral500, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                    color: AppColors.black, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_forward,
                    color: Colors.white, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Quick-commerce apps always surface "where am I ordering for" up top — this
// reads the customer's default (or first) saved address; with none saved yet
// it prompts to add one, tapping through to Profile's address CRUD either way.
class _LocationBar extends StatelessWidget {
  final AsyncValue profile;
  final VoidCallback onTap;
  const _LocationBar({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return profile.when(
      data: (customer) {
        final Customer c = customer as Customer;
        final addresses = c.addresses;
        final CustomerAddress? primary = addresses.isEmpty
            ? null
            : addresses.firstWhere((a) => a.isDefault,
                orElse: () => addresses.first);
        final label = primary == null
            ? 'Add your address'
            : (primary.label?.isNotEmpty == true
                ? primary.label!
                : 'Service address');
        final subtitle = primary == null
            ? 'Tap to add an address for faster booking'
            : '${primary.city}, ${primary.pinCode}';
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: AppColors.lime500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.location_on,
                      color: AppColors.lime500, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13.5)),
                      Text(subtitle,
                          style: const TextStyle(
                              color: AppColors.neutral500, fontSize: 11.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.neutral200),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(height: 54),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// Static assurance strip (verified professionals / on-time service / secure
// payments) — genuinely true of how the business operates already, not
// data-backed metrics, so kept as marketing copy rather than wired to any
// (nonexistent) backend source. Common on Urban Company/Blinkit-style
// dashboards to build trust above the fold.
class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.verified_user, 'Verified Pros'),
      (Icons.schedule, 'On-Time Service'),
      (Icons.lock, 'Secure Payments'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: items
            .map((item) => Expanded(
                  child: Column(
                    children: [
                      Icon(item.$1, color: AppColors.black, size: 20),
                      const SizedBox(height: 6),
                      Text(item.$2,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.neutral900)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// No icon data comes from the backend for a category (Master entities are
// just {id, label}) — this maps common category name keywords to a sensible
// icon rather than showing the same generic icon for every category. Falls
// back to a neutral icon for anything unrecognized, so it degrades safely as
// new categories get added in the admin panel.
IconData _iconForCategory(String label) {
  final l = label.toLowerCase();
  if (l.contains('ac') || l.contains('air')) return Icons.ac_unit;
  if (l.contains('electric')) return Icons.bolt;
  if (l.contains('plumb')) return Icons.plumbing;
  if (l.contains('clean')) return Icons.cleaning_services;
  if (l.contains('paint')) return Icons.format_paint;
  if (l.contains('carpent') || l.contains('wood')) return Icons.carpenter;
  if (l.contains('pest')) return Icons.pest_control;
  if (l.contains('beauty') || l.contains('salon') || l.contains('spa')) {
    return Icons.spa;
  }
  if (l.contains('appliance') || l.contains('repair')) return Icons.build;
  return Icons.miscellaneous_services;
}

// Cycled by position (not by category identity) purely to give the quick-
// access row visual variety instead of one flat tint repeated end to end.
const _categoryTints = [
  Color(0xFFEFF6FF),
  Color(0xFFFEF3E2),
  Color(0xFFF0FDF4),
  Color(0xFFFDF2F8),
  Color(0xFFF5F3FF),
];
const _categoryIconColors = [
  Color(0xFF2563EB),
  Color(0xFFD97706),
  Color(0xFF16A34A),
  Color(0xFFDB2777),
  Color(0xFF7C3AED),
];

class _CategoryQuickAccess extends StatelessWidget {
  final ServiceCategory category;
  final int colorIndex;
  const _CategoryQuickAccess(
      {required this.category, required this.colorIndex});

  @override
  Widget build(BuildContext context) {
    final tint = _categoryTints[colorIndex % _categoryTints.length];
    final iconColor =
        _categoryIconColors[colorIndex % _categoryIconColors.length];
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ServiceBrowseScreen(initialCategoryId: category.id))),
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ],
              ),
              child: Icon(_iconForCategory(category.label),
                  color: iconColor, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              category.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.neutral900,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// Real catalog data (same servicesByCategoryProvider(null) + serviceMediaProvider
// thumbnail-resolution used on the Browse screen), just laid out as a
// horizontal image-card rail instead of a list row — the "showcase" section
// a plain category-icon row doesn't give you.
class _PopularServiceCard extends ConsumerWidget {
  final Service service;
  const _PopularServiceCard({required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = ref.watch(serviceMediaProvider(service.id));
    final catalogRepo = ref.read(catalogRepositoryProvider);
    final thumbnailUrl = media.maybeWhen(
      data: (files) {
        final images = files.where((f) => !f.isVideo);
        return images.isEmpty
            ? null
            : catalogRepo.resolveMediaUrl(images.first);
      },
      orElse: () => null,
    );

    return SizedBox(
      width: 148,
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ServiceDetailScreen(serviceId: service.id))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18)),
                child: SizedBox(
                  height: 96,
                  width: double.infinity,
                  child: thumbnailUrl != null
                      ? Image.network(
                          thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const _ServiceCardPlaceholder(),
                          loadingBuilder: (context, child, progress) =>
                              progress == null
                                  ? child
                                  : const _ServiceCardPlaceholder(),
                        )
                      : const _ServiceCardPlaceholder(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12.5)),
                    const SizedBox(height: 4),
                    Text(
                        'From ₹${service.pricing.basePrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: AppColors.neutral500, fontSize: 11.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCardPlaceholder extends StatelessWidget {
  const _ServiceCardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.neutral100,
      child: const Icon(Icons.build_outlined,
          color: AppColors.neutral500, size: 26),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final ServiceRequestSummary request;
  const _RequestCard({required this.request});

  IconData _statusIcon(Color color) {
    if (color == Colors.red) return Icons.cancel_outlined;
    if (color == Colors.green) return Icons.check_circle_outline;
    if (color == Colors.orange) return Icons.hourglass_top;
    return Icons.build_circle_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final color = StatusBadge.colorFor(request.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  ServiceRequestDetailScreen(requestId: request.id))),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(_statusIcon(color), color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: Text(request.number,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14.5),
                                  overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        request.serviceName ?? '${request.priority} priority',
                        style: const TextStyle(
                            color: AppColors.neutral500, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(customerStatusLabel(request.status),
                          style: TextStyle(
                              color: color,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, color: AppColors.neutral200),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
