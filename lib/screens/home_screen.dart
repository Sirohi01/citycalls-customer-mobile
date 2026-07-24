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
                  child: _BookServiceCard(onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ServiceBrowseScreen()))),
                ),
              ],
            ),
            const SizedBox(height: 52),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _LocationBar(profile: profile, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()))),
            ),
            const SizedBox(height: 16),
            const _TrustStrip(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Categories', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: AppColors.black)),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ServiceBrowseScreen())),
                    style: TextButton.styleFrom(foregroundColor: AppColors.neutral500, padding: EdgeInsets.zero, minimumSize: Size.zero),
                    child: const Text('See all', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: categories.when(
                data: (cats) => cats.isEmpty
                    ? const SizedBox.shrink()
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cats.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 2.5,
                        ),
                        itemBuilder: (context, i) => _CategoryCard(category: cats[i], colorIndex: i),
                      ),
                loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 2),
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
    );
  }
}

class _Header extends ConsumerWidget {
  final String greeting;
  final AsyncValue profile;
  final int activeCount;
  final int completedCount;
  const _Header({required this.greeting, required this.profile, required this.activeCount, required this.completedCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beautyMode = ref.watch(beautyModeProvider);
    final gradientColors = beautyMode ? const [AppColors.beautyPrimary, Color(0xFFB23A56)] : const [AppColors.black, AppColors.neutral900];
    final blobColors = beautyMode ? const [Colors.white, Color(0xFFB23A56)] : const [AppColors.lime500, AppColors.indigo500];
    final ringColor = beautyMode ? Colors.white : AppColors.lime400;
    final activeAccent = beautyMode ? Colors.white : AppColors.lime400;

    return ClipRRect(
      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 56),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradientColors),
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
                Positioned(right: -60, top: -70, child: GlowBlob(color: blobColors[0], size: 220)),
                Positioned(left: -70, bottom: -40, child: GlowBlob(color: blobColors[1], size: 180)),
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
                              Text(greeting, style: TextStyle(color: beautyMode ? Colors.white70 : AppColors.slate400, fontSize: 13)),
                              const SizedBox(height: 3),
                              Text(customer.name, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                          loading: () => const SizedBox(height: 44),
                          error: (_, __) => const Text('Hi there', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ringColor, width: 1.5)),
                            child: CircleAvatar(radius: 20, backgroundColor: Colors.white.withValues(alpha: 0.15), child: const Icon(Icons.person_outline, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _StatChip(icon: Icons.bolt, label: 'Active', value: activeCount, accent: activeAccent)),
                        const SizedBox(width: 10),
                        Expanded(child: _StatChip(icon: Icons.task_alt, label: 'Completed', value: completedCount, accent: beautyMode ? Colors.white70 : AppColors.slate200)),
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
  const _StatChip({required this.icon, required this.label, required this.value, required this.accent});

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
              Text('$value', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, height: 1.1)),
              Text(label, style: const TextStyle(color: AppColors.slate400, fontSize: 10.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookServiceCard extends ConsumerWidget {
  final VoidCallback onTap;
  const _BookServiceCard({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beautyMode = ref.watch(beautyModeProvider);
    final accent = beautyMode ? AppColors.beautyPrimary : AppColors.lime500;
    final iconOnAccent = beautyMode ? Colors.white : AppColors.black;
    final circleColor = beautyMode ? AppColors.beautyPrimary : AppColors.black;

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
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                child: Icon(Icons.add_circle_outline, color: iconOnAccent),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Book a Service', style: TextStyle(color: AppColors.black, fontWeight: FontWeight.w700, fontSize: 15.5)),
                    SizedBox(height: 2),
                    Text('Browse our full service catalog', style: TextStyle(color: AppColors.neutral500, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
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
        final CustomerAddress? primary = addresses.isEmpty ? null : addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);
        final label = primary == null ? 'Add your address' : (primary.label?.isNotEmpty == true ? primary.label! : 'Service address');
        final subtitle = primary == null ? 'Tap to add an address for faster booking' : '${primary.city}, ${primary.pinCode}';
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                      Text(subtitle, style: const TextStyle(color: AppColors.neutral500, fontSize: 11.5), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                      Text(item.$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.neutral900)),
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
  if (l.contains('beauty') || l.contains('salon') || l.contains('bliss') || l.contains('spa')) {
    return Icons.spa;
  }
  if (l.contains('appliance') || l.contains('repair')) return Icons.build;
  return Icons.miscellaneous_services;
}

// Cycled by position (not by category identity) purely to give the category
// grid visual variety instead of one flat tint repeated end to end.
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

// Full-width, prominent cards — not the small icon-chip row this used to be.
// With only 4 real categories now (down from 20 demo ones), a tiny 76px-wide
// horizontal-scroll row undersold them; a 2-column grid gives each one
// enough visual weight to actually register as "here are our categories."
class _CategoryCard extends StatelessWidget {
  final ServiceCategory category;
  final int colorIndex;
  const _CategoryCard({required this.category, required this.colorIndex});

  @override
  Widget build(BuildContext context) {
    final tint = _categoryTints[colorIndex % _categoryTints.length];
    final iconColor = _categoryIconColors[colorIndex % _categoryIconColors.length];
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ServiceBrowseScreen(initialCategoryId: category.id))),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(10)),
                child: Icon(_iconForCategory(category.label), color: iconColor, size: 17),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  category.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.black, fontWeight: FontWeight.w700, height: 1.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// One horizontal rail of real services per category — this is what actually
// makes the dashboard "bigger"/richer with real content instead of a single
// generic list. Skips itself (SizedBox.shrink) when a category has no
// active services yet, rather than showing an empty titled section.
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
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(category.label, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: AppColors.black)),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ServiceBrowseScreen(initialCategoryId: category.id))),
                      style: TextButton.styleFrom(foregroundColor: AppColors.neutral500, padding: EdgeInsets.zero, minimumSize: Size.zero),
                      child: const Text('See all', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 190,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: items.length > 6 ? 6 : items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => _PopularServiceCard(service: items[i]),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 190, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// Real catalog data, laid out as a horizontal image-card rail — used by
// _CategoryServiceRail above (per-category) via servicesByCategoryProvider.
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
      width: 148,
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ServiceDetailScreen(serviceId: service.id))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
                child: SizedBox(
                  height: 96,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                    const SizedBox(height: 4),
                    Text('From ₹${service.pricing.basePrice.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.neutral500, fontSize: 11.5)),
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

