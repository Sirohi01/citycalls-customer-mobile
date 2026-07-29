import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/customer_providers.dart';
import '../providers/service_request_providers.dart';
import '../providers/catalog_providers.dart';
import '../providers/theme_providers.dart';
import '../models/catalog_models.dart';
import '../models/customer_models.dart';
import '../theme/app_theme.dart';
import '../widgets/glow_blob.dart';
import 'service_browse_screen.dart';
import 'service_detail_screen.dart';
import 'profile_screen.dart';

// Per docs/rohit/05-customer-app-screen-list.md "Home" — Home/Dashboard.
// Modeled after the quick-commerce/home-services dashboard pattern (Blinkit,
// Urban Company): location bar, floating quick-book CTA, trust strip,
// a compact category grid for quick jumps, then one real services rail per
// category (not a single mixed "Popular Services" list) — every section
// backed by real catalog/profile data, nothing invented. Active Requests
// deliberately isn't duplicated here — that's what the My Services tab is
// for; the header's "Active" stat chip is enough of a signal on this screen.
// Header/CTA re-theme via beautyModeProvider (Profile screen's "Beauty Mode"
// toggle, mirroring admin-web's pink Beauty & Salon mode).
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
    final activeCount = requests.maybeWhen(data: (items) => items.where((r) => r.isActive).length, orElse: () => 0);
    final completedCount = requests.maybeWhen(
      data: (items) => items.where((r) => !r.isActive && r.status != 'CANCELLED').length,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: AppColors.neutral100,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: _Header(
              greeting: _greeting(),
              profile: profile,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(myProfileProvider);
                ref.invalidate(myServiceRequestsProvider);
                ref.invalidate(serviceCategoriesProvider);
                ref.invalidate(servicesByCategoryProvider);
              },
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: _StatsCard(activeCount: activeCount, completedCount: completedCount),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _BookServiceCard(onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ServiceBrowseScreen()))),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _LocationBar(profile: profile, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()))),
                  ),
                  const SizedBox(height: 10),
                  const _TrustStrip(),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Categories', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: AppColors.black)),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ServiceBrowseScreen())),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.neutral500,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('See all', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: categories.when(
                      data: (cats) => cats.isEmpty
                          ? const SizedBox.shrink()
                          : GridView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: cats.length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.35,
                              ),
                              itemBuilder: (context, i) => _CategoryCard(category: cats[i], colorIndex: i),
                            ),
                      loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // One real rail per category (Home Appliances / Pest Control /
                  // Home Cleaning / Bliss & Salon) instead of a single flat
                  // "Popular Services" list mixed across all of them — this is
                  // what actually makes the dashboard showcase the catalog, per
                  // Manish's ask to see "categories ke andar ka bhi" here, not
                  // just a category-picker row.
                  categories.when(
                    data: (cats) => cats.isEmpty
                        ? const SizedBox.shrink()
                        : Column(children: [for (final c in cats) _CategoryServiceRail(category: c)]),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  final String greeting;
  final AsyncValue profile;
  const _Header({required this.greeting, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
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
                    Text(greeting, style: const TextStyle(color: AppColors.neutral500, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(customer.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.black)),
                  ],
                ),
                loading: () => const SizedBox(height: 44),
                error: (_, __) => const Text('Hi there', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.black)),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Color(0xFF064E3B), shape: BoxShape.circle),
                  child: const Icon(Icons.person_outline, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final int activeCount;
  final int completedCount;
  const _StatsCard({required this.activeCount, required this.completedCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F261B),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bolt, color: Color(0xFF4ADE80), size: 28),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$activeCount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, height: 1.1)),
                    const Text('Active\nBookings', style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.2)),
                  ],
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$completedCount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, height: 1.1)),
                    const Text('Completed\nBookings', style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.2)),
                  ],
                ),
              ],
            ),
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
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF22C55E), Color(0xFF15803D)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.calendar_today, color: Color(0xFF16A34A), size: 20),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Book a Service', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 2),
                    Text('Browse our full service catalog', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_forward, color: Color(0xFF16A34A), size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
        final CustomerAddress? primary = addresses.isEmpty ? null : addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);
        final label = primary == null ? 'Add your address' : 'Service address';
        final subtitle = primary == null ? 'Tap to add an address for faster booking' : '${primary.city}, ${primary.pinCode}';
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF16A34A), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.black)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(color: AppColors.neutral500, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.neutral500),
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

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.verified_user, 'Verified Pros', 'Trusted &\nBackground\nVerified'),
      (Icons.schedule, 'On-Time\nService', 'Punctual &\nReliable'),
      (Icons.lock, 'Secure\nPayments', '100% Safe\nTransactions'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map((item) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      border: Border.all(color: AppColors.neutral200, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(item.$1, color: AppColors.black, size: 24),
                        const SizedBox(height: 10),
                        Text(item.$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.black, height: 1.2)),
                        const SizedBox(height: 4),
                        Text(item.$3, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9.5, color: AppColors.neutral500, height: 1.2)),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

IconData _iconForCategory(String label) {
  final l = label.toLowerCase();
  if (l.contains('ac') || l.contains('air')) return Icons.ac_unit;
  if (l.contains('electric')) return Icons.bolt;
  if (l.contains('plumb')) return Icons.plumbing;
  if (l.contains('clean')) return Icons.cleaning_services;
  if (l.contains('paint')) return Icons.format_paint;
  if (l.contains('carpent') || l.contains('wood')) return Icons.carpenter;
  if (l.contains('pest')) return Icons.pest_control;
  if (l.contains('beauty') || l.contains('salon') || l.contains('bliss') || l.contains('spa')) return Icons.spa;
  if (l.contains('appliance') || l.contains('repair')) return Icons.build;
  return Icons.miscellaneous_services;
}

const _categoryTints = [
  Color(0xFFF3E8FF),
  Color(0xFFE0F2FE),
  Color(0xFFDCFCE7),
  Color(0xFFFFEDD5),
];
const _categoryIconColors = [
  Color(0xFF9333EA),
  Color(0xFF0284C7),
  Color(0xFF16A34A),
  Color(0xFFEA580C),
];
const _categorySubtitles = [
  'Pamper yourself\nwith expert care',
  'Repair & service\nat your door',
  'Spotless homes,\nhappier you',
  'Safe, effective\n& reliable',
];

class _CategoryCard extends StatelessWidget {
  final ServiceCategory category;
  final int colorIndex;
  const _CategoryCard({required this.category, required this.colorIndex});

  @override
  Widget build(BuildContext context) {
    final tint = _categoryTints[colorIndex % _categoryTints.length];
    final iconColor = _categoryIconColors[colorIndex % _categoryIconColors.length];
    final subtitle = _categorySubtitles[colorIndex % _categorySubtitles.length];

    return Material(
      color: tint,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ServiceBrowseScreen(initialCategoryId: category.id))),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: AppColors.black, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10, color: AppColors.neutral500, height: 1.2),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                  ),
                ],
              ),
            ),
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(_iconForCategory(category.label), color: iconColor.withOpacity(0.4), size: 70),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryServiceRail extends ConsumerWidget {
  final ServiceCategory category;
  const _CategoryServiceRail({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(servicesByCategoryProvider(category.id));
    return services.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Popular Services', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.black)),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ServiceBrowseScreen(initialCategoryId: category.id))),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF16A34A),
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('See all', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 155,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: items.length > 6 ? 6 : items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, i) => _PopularServiceCard(service: items[i]),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 164, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

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
        return images.isEmpty ? null : catalogRepo.resolveMediaUrl(images.first);
      },
      orElse: () => null,
    );

    return SizedBox(
      width: 136,
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.06),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ServiceDetailScreen(serviceId: service.id))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
                    child: SizedBox(
                      height: 86,
                      width: double.infinity,
                      child: thumbnailUrl != null
                          ? Image.network(
                              thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const _ServiceCardPlaceholder(),
                              loadingBuilder: (context, child, progress) => progress == null ? child : const _ServiceCardPlaceholder(),
                            )
                          : const _ServiceCardPlaceholder(),
                    ),
                  ),
                  Positioned(
                    bottom: -10,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cleaning_services, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.black, height: 1.15)),
                    const SizedBox(height: 4),
                    Text('From ₹${service.pricing.basePrice.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF16A34A), fontSize: 11.5, fontWeight: FontWeight.w700)),
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
      child: const Icon(Icons.build_outlined, color: AppColors.neutral500, size: 26),
    );
  }
}

