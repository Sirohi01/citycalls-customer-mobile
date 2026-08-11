import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/customer_providers.dart';
import '../providers/service_request_providers.dart';
import '../providers/catalog_providers.dart';
import '../models/catalog_models.dart';
import '../models/customer_models.dart';
import 'service_browse_screen.dart';
import 'service_detail_screen.dart';
import 'profile_screen.dart';
import '../widgets/custom_top_bar.dart';
import '../widgets/app_drawer.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider);
    final requests = ref.watch(myServiceRequestsProvider);
    final categories = ref.watch(serviceCategoriesProvider);
    
    final activeCount = requests.maybeWhen(
        data: (items) => items.where((r) => r.isActive).length,
        orElse: () => 0);
    final completedCount = requests.maybeWhen(
      data: (items) =>
          items.where((r) => !r.isActive && r.status != 'CANCELLED').length,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppDrawer(),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const CustomTopBar(),
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF16A34A),
                onRefresh: () async {
                  ref.invalidate(myProfileProvider);
                  ref.invalidate(myServiceRequestsProvider);
                  ref.invalidate(serviceCategoriesProvider);
                  ref.invalidate(servicesByCategoryProvider);
                },
                child: ListView(
                  padding: const EdgeInsets.only(top: 0, bottom: 24),
                  children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _HeroBanner(),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _StatsCard(
                    activeCount: activeCount,
                    completedCount: completedCount),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Explore Categories',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ServiceBrowseScreen(),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                        child: Row(
                          children: [
                            Text(
                              'See all',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 11, color: Color(0xFF16A34A)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: categories.when(
                  data: (cats) => cats.isEmpty
                      ? const SizedBox.shrink()
                      : GridView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: cats.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.35,
                          ),
                          itemBuilder: (context, i) => _CategoryCard(
                              category: cats[i], colorIndex: i),
                        ),
                  loading: () => const SizedBox(
                    height: 120,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 16),
              categories.when(
                data: (cats) => cats.isEmpty
                    ? const SizedBox.shrink()
                    : Column(
                        children: [
                          for (final c in cats)
                            _CategoryServiceRail(category: c)
                        ],
                      ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
              ),
            ],
          ),
        ),
    );
  }
}

class _HeroBanner extends StatefulWidget {
  const _HeroBanner();

  @override
  State<_HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<_HeroBanner> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title1': 'We Are Just\\n',
      'title2': 'A Call Away',
      'subtitle': 'Book trusted professionals\\nat your doorstep',
      'imageUrl': 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?q=80&w=800&auto=format&fit=crop',
      'buttonColor': const Color(0xFF16A34A),
    },
    {
      'title1': 'Flat 20% Off\\n',
      'title2': 'On AC Repair',
      'subtitle': 'Beat the summer heat with\\nour expert technicians',
      'imageUrl': 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?q=80&w=800&auto=format&fit=crop',
      'buttonColor': const Color(0xFF2563EB),
    },
    {
      'title1': 'Deep Cleaning\\n',
      'title2': 'Starts at ₹999',
      'subtitle': 'Give your home the shine\\nit deserves today',
      'imageUrl': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=800&auto=format&fit=crop',
      'buttonColor': const Color(0xFFDC2626),
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentPage = _slides.length * 1000; // Start high to allow swiping left
    _pageController = PageController(initialPage: _currentPage);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final nextPage = _currentPage + 1;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFFF1F5F9), // Fallback color
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final slide = _slides[index % _slides.length];
                return Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(slide['imageUrl'] as String),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.7),
                              Colors.black.withValues(alpha: 0.1),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                      // Content
                      Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.2,
                              ),
                              children: [
                                TextSpan(text: slide['title1'] as String),
                                TextSpan(
                                  text: slide['title2'] as String,
                                  style: TextStyle(color: slide['buttonColor'] as Color),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            slide['subtitle'] as String,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFE2E8F0),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: slide['buttonColor'] as Color,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Book Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
            },
          ),
        ),
        Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) {
                  final activeIndex = _currentPage % _slides.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: activeIndex == index ? 16 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: activeIndex == index
                          ? _slides[activeIndex]['buttonColor'] as Color
                          : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                },
              ),
            ),
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
    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0), width: 1.2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt_rounded, color: Color(0xFF16A34A), size: 22),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$activeCount Active', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF166534), letterSpacing: -0.2)),
                        const Text('Bookings', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF22C55E))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF94A3B8), size: 20),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$completedCount Done', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF334155), letterSpacing: -0.2)),
                        const Text('Past jobs', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}



IconData _iconForCategory(String label) {
  final l = label.toLowerCase();
  if (l.contains('ac') || l.contains('air')) return Icons.ac_unit_rounded;
  if (l.contains('electric')) return Icons.bolt_rounded;
  if (l.contains('plumb')) return Icons.plumbing_rounded;
  if (l.contains('clean')) return Icons.cleaning_services_rounded;
  if (l.contains('paint')) return Icons.format_paint_rounded;
  if (l.contains('carpent') || l.contains('wood')) return Icons.carpenter_rounded;
  if (l.contains('pest')) return Icons.pest_control_rounded;
  if (l.contains('beauty') ||
      l.contains('salon') ||
      l.contains('bliss') ||
      l.contains('spa')) {
    return Icons.spa_rounded;
  }
  if (l.contains('appliance') || l.contains('repair')) return Icons.build_rounded;
  return Icons.miscellaneous_services_rounded;
}

const _categoryTints = [
  Color(0xFFFAF5FF),
  Color(0xFFF0F9FF),
  Color(0xFFF0FDF4),
  Color(0xFFFFFAF0),
];
const _categoryIconColors = [
  Color(0xFF9333EA),
  Color(0xFF0284C7),
  Color(0xFF16A34A),
  Color(0xFFEA580C),
];
const _categorySubtitles = [
  'Expert salon care',
  'Quick repairs',
  'Spotless cleaning',
  'Safe & reliable',
];

class _CategoryCard extends StatelessWidget {
  final ServiceCategory category;
  final int colorIndex;
  const _CategoryCard({required this.category, required this.colorIndex});

  @override
  Widget build(BuildContext context) {
    final tint = _categoryTints[colorIndex % _categoryTints.length];
    final iconColor =
        _categoryIconColors[colorIndex % _categoryIconColors.length];
    final subtitle = _categorySubtitles[colorIndex % _categorySubtitles.length];

    return Material(
      color: tint,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ServiceBrowseScreen(initialCategoryId: category.id),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: iconColor.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
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
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: iconColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 12),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: -8,
                bottom: -8,
                child: Icon(_iconForCategory(category.label),
                    color: iconColor.withValues(alpha: 0.15), size: 64),
              ),
            ],
          ),
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
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ServiceBrowseScreen(
                            initialCategoryId: category.id,
                          ),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 4, horizontal: 2),
                        child: Text(
                          'View all',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 165,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length > 6 ? 6 : items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) =>
                      _PopularServiceCard(service: items[i]),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
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
        return images.isEmpty
            ? null
            : catalogRepo.resolveMediaUrl(images.first);
      },
      orElse: () => null,
    );

    return SizedBox(
      width: 140,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ServiceDetailScreen(serviceId: service.id),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                      ),
                      child: SizedBox(
                        height: 90,
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
                    Positioned(
                      bottom: -8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(Icons.add_rounded,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: Color(0xFF0F172A),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹${service.pricing.basePrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Color(0xFF16A34A),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Icon(Icons.home_repair_service_rounded,
            color: Color(0xFF94A3B8), size: 28),
      ),
    );
  }
}
