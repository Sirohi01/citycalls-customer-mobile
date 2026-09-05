import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/customer_providers.dart';
import '../providers/service_request_providers.dart';
import '../providers/catalog_providers.dart';
import '../models/catalog_models.dart';
import 'service_browse_screen.dart';
import 'service_detail_screen.dart';
import '../widgets/custom_top_bar.dart';
import '../widgets/app_drawer.dart';
import '../theme/app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    Color(0xFFF6EAF6), // Soft purple/pink glow top-left
                    Color(0xFFECF1FD), // Soft blue glow top-right
                    Color(0xFFF8FAFC), // Fade to normal background
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
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
              const SizedBox(height: 7), // Reduced spacing
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 16),
              //   child: _StatsCard(
              //       activeCount: activeCount,
              //       completedCount: completedCount),
              // ),
              // const SizedBox(height: 12),
              const _TopCategoriesSection(),
              const SizedBox(height: 16),
              categories.when(
                data: (cats) {
                  final displayCats = cats.where((c) => !c.label.toLowerCase().contains('bliss') && !c.label.toLowerCase().contains('salon')).toList();
                  if (displayCats.isEmpty) return const SizedBox.shrink();
                  return Column(
                    children: [
                      for (final c in displayCats)
                        if (c.label.toLowerCase().contains('appliance') ||
                            c.label.toLowerCase().contains('cleaning') ||
                            c.label.toLowerCase().contains('pest'))
                          _ApplianceServiceList(category: c)
                        else
                          _CategoryServiceRail(category: c)
                    ],
                  );
                },
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
        ],
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
      'title1': 'We Are Just\n',
      'title2': 'A Call Away',
      'subtitle': 'Book trusted professionals\nat your doorstep',
      'imageUrl': 'assets/home/home_bannar.png',
      'buttonColor': const Color(0xFF16A34A),
    },
    {
      'title1': 'Flat 20% Off\n',
      'title2': 'On AC Repair',
      'subtitle': 'Beat the summer heat with\nour expert technicians',
      'imageUrl': 'assets/home/home_bannar2.png',
      'buttonColor': const Color(0xFF2563EB),
    },
    {
      'title1': 'Deep Cleaning\n',
      'title2': 'Starts at ₹999',
      'subtitle': 'Give your home the shine\nit deserves today',
      'imageUrl': 'assets/home/home_bannar3.png',
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
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        final nextPage = _currentPage + 1;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 700),
          curve: Curves.fastOutSlowIn,
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
      height: 165,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFFF8FAFC),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
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
                final buttonColor = slide['buttonColor'] as Color;
                return Stack(
                  children: [
                    // Background Image
                    Positioned.fill(
                      child: Image(
                        image: (slide['imageUrl'] as String).startsWith('http')
                            ? NetworkImage(slide['imageUrl'] as String)
                            : AssetImage(slide['imageUrl'] as String) as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // No gradient overlay as requested
                    // Content
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  height: 1.2,
                                  letterSpacing: -0.5,
                                ),
                                children: [
                                  TextSpan(text: slide['title1'] as String),
                                  TextSpan(
                                    text: slide['title2'] as String,
                                    style: TextStyle(color: buttonColor),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              slide['subtitle'] as String,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            /*
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonColor,
                                foregroundColor: Colors.white,
                                elevation: 3,
                                shadowColor: buttonColor.withValues(alpha: 0.3),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Book Now',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11.5,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white),
                                ],
                              ),
                            ),
                            */
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Navigation Dots
          Positioned(
            bottom: 14,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: List.generate(
                _slides.length,
                (index) {
                  final activeIndex = _currentPage % _slides.length;
                  final isActive = activeIndex == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isActive ? 24 : 6,
                    height: 6,
                    margin: const EdgeInsets.only(left: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? _slides[activeIndex]['buttonColor'] as Color
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
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

class _TopCategoriesSection extends ConsumerStatefulWidget {
  const _TopCategoriesSection({super.key});

  @override
  ConsumerState<_TopCategoriesSection> createState() => _TopCategoriesSectionState();
}

class _TopCategoriesSectionState extends ConsumerState<_TopCategoriesSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(serviceCategoriesProvider);

    return categories.when(
      data: (cats) {
        final displayCats = cats.where((c) => !c.label.toLowerCase().contains('bliss') && !c.label.toLowerCase().contains('salon')).toList();
        if (displayCats.isEmpty) return const SizedBox.shrink();

        final itemsToShow = _expanded ? displayCats.length : (displayCats.length > 4 ? 3 : displayCats.length);
        final showMoreBtn = !_expanded && displayCats.length > 4;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Top Categories',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 16,
                alignment: WrapAlignment.start,
                children: [
                  for (int i = 0; i < itemsToShow; i++)
                    _buildCategoryItem(displayCats[i], i),
                  if (showMoreBtn) _buildMoreButton(),
                  if (_expanded && displayCats.length > 4) _buildLessButton(),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF16A34A)),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCategoryItem(ServiceCategory category, int index) {
    // 4 items per row with 12px spacing -> 3 * 12 = 36px total spacing
    // Plus 32px horizontal padding -> 68px total padding/spacing
    final width = (MediaQuery.of(context).size.width - 68) / 4;
    final iconColor = _categoryIconColors[index % _categoryIconColors.length];

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ServiceBrowseScreen(initialCategoryId: category.id),
        ),
      ),
      child: SizedBox(
        width: width,
        child: Column(
          children: [
            Container(
              height: width,
              width: width,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 1),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))
                ],
              ),
              child: ref.watch(masterMediaProvider(category.id)).when(
                data: (media) {
                  final img = media.where((m) => m.category == 'CATALOG_IMAGE').firstOrNull;
                  if (img != null) {
                    final url = ref.read(catalogRepositoryProvider).resolveMediaUrl(img);
                    print('Category ${category.label} Image URL: $url');
                    return Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Image.network(
                        url,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          print('Image load failed for $url: $error');
                          return Icon(_iconForCategory(category.label), color: iconColor, size: 30);
                        },
                      ),
                    );
                  }
                  return Center(
                    child: Icon(_iconForCategory(category.label), color: iconColor, size: 30),
                  );
                },
                loading: () => const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                error: (_, __) => Center(child: Icon(_iconForCategory(category.label), color: iconColor, size: 30)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.2, color: Color(0xFF334155)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreButton() {
    final width = (MediaQuery.of(context).size.width - 68) / 4;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _expanded = true;
        });
      },
      child: SizedBox(
        width: width,
        child: Column(
          children: [
            Container(
              height: width,
              width: width,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 1),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))
                ],
              ),
              child: const Center(
                child: Icon(Icons.more_horiz_rounded, color: Colors.grey, size: 30),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'More\nServices',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.2, color: Color(0xFF334155)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessButton() {
    final width = (MediaQuery.of(context).size.width - 68) / 4;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _expanded = false;
        });
      },
      child: SizedBox(
        width: width,
        child: Column(
          children: [
            Container(
              height: width,
              width: width,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 1),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))
                ],
              ),
              child: const Center(
                child: Icon(Icons.unfold_less_rounded, color: Colors.grey, size: 30),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Show\nLess',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.2, color: Color(0xFF334155)),
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

class _ApplianceServiceList extends ConsumerStatefulWidget {
  final ServiceCategory category;
  const _ApplianceServiceList({required this.category});

  @override
  ConsumerState<_ApplianceServiceList> createState() => _ApplianceServiceListState();
}

class _ApplianceServiceListState extends ConsumerState<_ApplianceServiceList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesByCategoryProvider(widget.category.id));
    
    return servicesAsync.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        
        final itemsToShow = _expanded ? items.length : (items.length > 4 ? 4 : items.length);
        
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.category.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (items.length > 4)
                      InkWell(
                        onTap: () => setState(() => _expanded = !_expanded),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                          child: Text(
                            _expanded ? 'View less' : 'View all',
                            style: const TextStyle(
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
              const SizedBox(height: 6),
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                itemCount: itemsToShow,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, i) => _ApplianceServiceCard(service: items[i]),
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

class _ApplianceServiceCard extends ConsumerWidget {
  final Service service;
  const _ApplianceServiceCard({required this.service});

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

    // Mock rating based on string length to give it a realistic varied look like the design
    final rating = (4.0 + (service.name.length % 10) / 10).toStringAsFixed(1);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ServiceDetailScreen(serviceId: service.id))),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 60,
                    height: 60,
                    color: AppColors.white,
                    child: thumbnailUrl != null
                        ? Image.network(
                            thumbnailUrl,
                            fit: BoxFit.contain, // So the appliance image fits nicely without cropping
                            errorBuilder: (_, __, ___) => const Icon(Icons.build_outlined, color: AppColors.neutral500),
                          )
                        : const Icon(Icons.build_outlined, color: AppColors.neutral500),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(service.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('Starting at ₹${service.pricing.basePrice.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Color(0xFF16A34A), size: 16),
                    const SizedBox(width: 4),
                    Text(rating, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                    const SizedBox(width: 12),
                    const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
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
