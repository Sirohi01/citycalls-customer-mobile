import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/customer_providers.dart';
import '../providers/service_request_providers.dart';
import '../providers/catalog_providers.dart';
import '../models/catalog_models.dart';
import 'service_browse_screen.dart';
import 'service_detail_screen.dart';
import '../widgets/custom_top_bar.dart';
import '../widgets/app_drawer.dart';
import '../widgets/state_views.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(serviceCategoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppDrawer(),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Column(
          children: [
            Container(
              // The dark header and the dark banner strip below it are two
              // separate boxes; a 1px dark shadow covers the sub-pixel seam
              // that otherwise shows as a light line under the search bar.
              decoration: const BoxDecoration(
                color: _kHeroDark,
                boxShadow: [
                  BoxShadow(color: _kHeroDark, offset: Offset(0, 1)),
                ],
              ),
              child: const SafeArea(
                bottom: false,
                child: CustomTopBar(),
              ),
            ),
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
                    // Padding(
                    //   padding: const EdgeInsets.symmetric(horizontal: 16),
                    //   child: _StatsCard(
                    //       activeCount: activeCount,
                    //       completedCount: completedCount),
                    // ),
                    // const SizedBox(height: 12),
                    // No bottom padding: the banner ends the header block,
                    // with no strip of header colour beneath it.
                    Container(
                      color: _kHeroDark,
                      child: const Column(
                        children: [
                          TopBarLocationSearch(),
                          _HeroBanner(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const _TopCategoriesSection(),
                    const SizedBox(height: 12),
                    // Divider + heading so the promo carousel reads as its
                    // own section rather than part of the category grid.
                    const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Color(0xFFE2E8F0),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Offers & Deals',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: _PromoBanner(),
                    ),
                    const SizedBox(height: 16),
                    categories.when(
                      data: (cats) => Column(
                        children: [
                          for (int i = 0; i < cats.length; i++)
                            _CategoryServiceSection(
                              category: cats[i],
                              accent: _categoryIconColors[
                                  i % _categoryIconColors.length],
                            ),
                        ],
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (err, __) => AppErrorView(
                        error: err,
                        compact: true,
                        onRetry: () =>
                            ref.invalidate(serviceCategoriesProvider),
                      ),
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

// Dark hero header (top bar + banner) sitting above "Our Categories".
const _kHeroDark = Color(0xFF0B0B0B);
const _kHeroLime = Color(0xFF8BD450);

typedef _HeroSlide = ({
  String tag,
  String title1,
  String title2,
  String subtitle,
  // Asset path (bundled fallback) or http(s) URL (from the API).
  String? image,
  IconData icon,
  String button,
});

// Static home top banners, bundled with the app (assets/home_top_bannar/).
const List<_HeroSlide> _homeHeroSlides = [
  (
    tag: 'Trusted Professionals',
    title1: 'AC Service',
    title2: '& Repair',
    subtitle: 'Expert technicians for cooling,\ngas refill and installation.',
    image: 'assets/home_top_bannar/ac-bannar.png',
    icon: Icons.ac_unit_rounded,
    button: 'Book a Service',
  ),
  (
    tag: 'Doorstep Service',
    title1: 'Washing Machine',
    title2: 'Repair',
    subtitle: 'Front-load, top-load and\nsemi-automatic — all brands.',
    image: 'assets/home_top_bannar/wosing-bannar.png',
    icon: Icons.local_laundry_service_rounded,
    button: 'Book a Service',
  ),
  (
    tag: 'Brand Experts',
    title1: 'Refrigerator',
    title2: 'Repair',
    subtitle: 'Cooling issues, gas refill\nand compressor repair.',
    image: 'assets/home_top_bannar/frez-bannar.png',
    icon: Icons.kitchen_rounded,
    button: 'Book a Service',
  ),
  (
    tag: 'Pure Water',
    title1: 'RO Purifier',
    title2: 'Service',
    subtitle: 'Filter change, repair and\nregular maintenance.',
    image: 'assets/home_top_bannar/ro-bannar.png',
    icon: Icons.water_drop_rounded,
    button: 'Book a Service',
  ),
  (
    tag: 'Same Day Visit',
    title1: 'TV Repair',
    title2: '& Installation',
    subtitle: 'LED, LCD and Smart TV\nrepair and wall mounting.',
    image: 'assets/home_top_bannar/tv-bannar.png',
    icon: Icons.tv_rounded,
    button: 'Book a Service',
  ),
  (
    tag: 'Deep Cleaning',
    title1: 'Kitchen Chimney',
    title2: 'Service',
    subtitle: 'Deep cleaning and repair\nfor a smoke-free kitchen.',
    image: 'assets/home_top_bannar/chemni-bannar.png',
    icon: Icons.cleaning_services_rounded,
    button: 'Book a Service',
  ),
];

class _HeroBanner extends StatefulWidget {
  final List<_HeroSlide> slides;
  final Color accent;
  final Color cardColor;
  final String? categoryId;
  // Light card (e.g. the Salon tab): dark titles, an accent-filled button
  // and a thin accent border, for banner photos that are light on the left.
  final bool lightCard;

  const _HeroBanner({
    this.slides = _homeHeroSlides,
    this.accent = _kHeroLime,
    this.cardColor = const Color(0xFF151515),
    this.categoryId,
    this.lightCard = false,
  });

  @override
  State<_HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<_HeroBanner> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  List<_HeroSlide> get _slides => widget.slides;

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
        _pageController.animateToPage(
          _currentPage + 1,
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
      // Edge to edge across the screen — no side margin or rounded corners.
      height: 190,
      decoration: BoxDecoration(
        color: widget.cardColor,
        boxShadow: widget.lightCard
            ? [
                BoxShadow(
                  color: widget.accent.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          ClipRect(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) =>
                  _buildSlide(context, _slides[index % _slides.length]),
            ),
          ),
          // Navigation Dots
          Positioned(
            bottom: 14,
            right: 16,
            child: Row(
              children: List.generate(_slides.length, (index) {
                final isActive = _currentPage % _slides.length == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isActive ? 18 : 10,
                  height: 6,
                  margin: const EdgeInsets.only(left: 5),
                  decoration: BoxDecoration(
                    color: isActive
                        ? widget.accent
                        : widget.lightCard
                            ? widget.accent.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(BuildContext context, _HeroSlide slide) {
    final accent = widget.accent;
    final card = widget.cardColor;
    final light = widget.lightCard;
    // Light cards: near-black titles tinted with the tab's accent (plum on
    // Salon, dark brown on HelpNow).
    final titleColor = light
        ? Color.alphaBlend(
            accent.withValues(alpha: 0.22), const Color(0xFF111111))
        : Colors.white;
    final subtitleColor = light
        ? Color.alphaBlend(
            accent.withValues(alpha: 0.18), const Color(0xFF4B5563))
        : Colors.white;
    final image = slide.image;
    return Stack(
      children: [
        // Full-bleed banner photo (dark on the left, so the text below stays
        // readable). Without a photo, a large glowing icon fills the right
        // side instead.
        if (image != null)
          Positioned.fill(
            child: image.startsWith('http')
                ? Image.network(
                    image,
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                    // Fade the photo in over the dark card instead of popping.
                    frameBuilder: (_, child, frame, syncLoaded) =>
                        AnimatedOpacity(
                      opacity: syncLoaded || frame != null ? 1 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: child,
                    ),
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  )
                : Image.asset(
                    image,
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                  ),
          )
        else ...[
          Positioned(
            right: -40,
            top: -30,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  accent.withValues(alpha: 0.35),
                  accent.withValues(alpha: 0.0),
                ]),
              ),
            ),
          ),
          Positioned(
            right: 22,
            top: 34,
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.12),
                border: Border.all(
                    color: accent.withValues(alpha: 0.5), width: 1.5),
              ),
              child: Icon(slide.icon, color: accent, size: 54),
            ),
          ),
        ],
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                // A light card's photos are already light on the left, so
                // only a soft wash goes over them — a heavy one makes the
                // whole banner look washed-out white.
                // On a light card the text side gets a soft white wash
                // (not the pink card colour) so the dark text stands out.
                colors: light && image != null
                    ? [
                        Colors.white.withValues(alpha: 0.75),
                        Colors.white.withValues(alpha: 0.45),
                        Colors.white.withValues(alpha: 0.0),
                      ]
                    // Dark cards: the photos are already dark on the left, so
                    // a lighter fade keeps the white text readable without
                    // blacking out half the photo.
                    : image != null
                        ? [
                            card.withValues(alpha: 0.8),
                            card.withValues(alpha: 0.45),
                            card.withValues(alpha: 0.0),
                          ]
                        : [
                            card,
                            card.withValues(alpha: 0.6),
                            card.withValues(alpha: 0.0),
                          ],
                stops: light && image != null
                    ? const [0.0, 0.42, 0.65]
                    : image != null
                        ? const [0.0, 0.38, 0.62]
                        : const [0.0, 0.45, 0.7],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent, width: 1),
                ),
                child: Text(
                  slide.tag,
                  style: TextStyle(
                    color: accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                slide.title1,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                slide.title2,
                style: TextStyle(
                  color: accent,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                slide.subtitle,
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
              const Spacer(),
              Material(
                color: light ? accent : Colors.white,
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ServiceBrowseScreen(
                          initialCategoryId: widget.categoryId))),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          slide.button,
                          style: TextStyle(
                            color: light
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.chevron_right_rounded,
                            size: 18,
                            color: light
                                ? Colors.white
                                : const Color(0xFF0F172A)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// The original light promo carousel, shown below "Our Categories".
class _PromoBanner extends StatefulWidget {
  const _PromoBanner();

  @override
  State<_PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<_PromoBanner> {
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
                            : AssetImage(slide['imageUrl'] as String)
                                as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Content
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
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

IconData _iconForCategory(String label) {
  final l = label.toLowerCase();
  if (l.contains('ac') || l.contains('air')) {
    return Icons.ac_unit_rounded;
  }
  if (l.contains('electric')) {
    return Icons.bolt_rounded;
  }
  if (l.contains('plumb')) {
    return Icons.plumbing_rounded;
  }
  if (l.contains('clean')) {
    return Icons.cleaning_services_rounded;
  }
  if (l.contains('paint')) {
    return Icons.format_paint_rounded;
  }
  if (l.contains('carpent') || l.contains('wood')) {
    return Icons.carpenter_rounded;
  }
  if (l.contains('pest')) {
    return Icons.pest_control_rounded;
  }
  if (l.contains('beauty') ||
      l.contains('salon') ||
      l.contains('bliss') ||
      l.contains('spa')) {
    return Icons.spa_rounded;
  }
  if (l.contains('appliance') || l.contains('repair')) {
    return Icons.build_rounded;
  }
  return Icons.miscellaneous_services_rounded;
}

const _categoryIconColors = [
  Color(0xFF9333EA),
  Color(0xFF0284C7),
  Color(0xFF16A34A),
  Color(0xFFEA580C),
];

// Service.expectedDurationMinutes rendered for a customer (service detail
// and favourites; the home grid cards no longer show it).
String formatServiceDuration(int minutes) {
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (rest == 0) return hours == 1 ? '1 hr' : '$hours hrs';
  return '$hours hr $rest min';
}

// Grid shows up to 3 rows of 3 (9 slots). Categories beyond that are reached
// via the 9th slot turning into a "More Services" card instead of trying to
// cram them all in, or an expand/collapse toggle.
const _maxGridSlots = 9;
const _categoryGridSpacing = 12.0;

// 3 tiles per row: screen minus 16px side padding and two 12px gaps.
double _categoryTileWidth(BuildContext context) =>
    (MediaQuery.of(context).size.width - 32 - 2 * _categoryGridSpacing) / 3;

class _TopCategoriesSection extends ConsumerWidget {
  const _TopCategoriesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(serviceCategoriesProvider);

    return categories.when(
      data: (cats) {
        final displayCats = cats
            .where((c) =>
                !c.label.toLowerCase().contains('bliss') &&
                !c.label.toLowerCase().contains('salon'))
            .toList();
        if (displayCats.isEmpty) return const SizedBox.shrink();

        final showMoreCard = displayCats.length > _maxGridSlots;
        final itemsToShow =
            showMoreCard ? _maxGridSlots - 1 : displayCats.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Our Categories',
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
                spacing: _categoryGridSpacing,
                runSpacing: 14,
                alignment: WrapAlignment.start,
                children: [
                  for (int i = 0; i < itemsToShow; i++)
                    _buildCategoryItem(context, ref, displayCats[i], i),
                  if (showMoreCard) _buildMoreCard(context),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(
              strokeWidth: 2.5, color: Color(0xFF16A34A)),
        ),
      ),
      error: (err, __) => AppErrorView(
        error: err,
        compact: true,
        onRetry: () => ref.invalidate(serviceCategoriesProvider),
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, WidgetRef ref,
      ServiceCategory category, int index) {
    final width = _categoryTileWidth(context);
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
                // Soft tint of the category's accent colour.
                color: iconColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: iconColor.withValues(alpha: 0.15), width: 1),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: ref.watch(masterMediaProvider(category.id)).when(
                    data: (media) {
                      final img = media
                          .where((m) => m.category == 'CATALOG_IMAGE')
                          .firstOrNull;
                      if (img != null) {
                        final url = ref
                            .read(catalogRepositoryProvider)
                            .resolveMediaUrl(img);
                        return Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Image.network(
                            url,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                                _iconForCategory(category.label),
                                color: iconColor,
                                size: 38),
                          ),
                        );
                      }
                      return Center(
                        child: Icon(_iconForCategory(category.label),
                            color: iconColor, size: 38),
                      );
                    },
                    loading: () => const Center(
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))),
                    error: (_, __) => Center(
                        child: Icon(_iconForCategory(category.label),
                            color: iconColor, size: 38)),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              category.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: Color(0xFF334155)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreCard(BuildContext context) {
    final width = _categoryTileWidth(context);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ServiceBrowseScreen()),
      ),
      child: SizedBox(
        width: width,
        child: Column(
          children: [
            Container(
              height: width,
              width: width,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: const Center(
                child: Icon(Icons.more_horiz_rounded,
                    color: Colors.grey, size: 38),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'More\nServices',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: Color(0xFF334155)),
            ),
          ],
        ),
      ),
    );
  }
}

// One block per category below the promo banner: the category name, a
// "View more" link when it has more than [_homeServicesPerCategory] services,
// and the first few services as list cards.
const _homeServicesPerCategory = 6;

class _CategoryServiceSection extends ConsumerWidget {
  final ServiceCategory category;
  final Color accent;
  const _CategoryServiceSection({required this.category, required this.accent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesByCategoryProvider(category.id));
    final items = servicesAsync.valueOrNull ?? const <Service>[];
    final hasMore = items.length > _homeServicesPerCategory;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    category.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (hasMore)
                  InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ServiceBrowseScreen(initialCategoryId: category.id),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      child: Text(
                        'View more',
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
          // Thin rule just under the name / "View more" row, same style as
          // the one above "Offers & Deals".
          const SizedBox(height: 4),
          const Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color: Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 10),
          servicesAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Text(
                    'Services coming soon',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                  ),
                );
              }
              final count = hasMore ? _homeServicesPerCategory : items.length;
              // Two cards per row.
              final cardWidth =
                  (MediaQuery.of(context).size.width - 32 - 12) / 2;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (int i = 0; i < count; i++)
                      SizedBox(
                        width: cardWidth,
                        child:
                            _ServiceGridCard(service: items[i], accent: accent),
                      ),
                  ],
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF16A34A)),
                ),
              ),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(
                "Couldn't load services",
                style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceGridCard extends ConsumerWidget {
  final Service service;
  final Color accent;
  const _ServiceGridCard({required this.service, required this.accent});

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
    // No photo: a wash of the category's accent with its service icon, so the
    // card keeps the same shape and the text still sits on a dark fade.
    final placeholder = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(accent.withValues(alpha: 0.35), Colors.white),
            accent,
          ],
        ),
      ),
      child: Align(
        alignment: const Alignment(0, -0.35),
        child: Icon(Icons.home_repair_service_rounded,
            color: Colors.white.withValues(alpha: 0.85), size: 32),
      ),
    );

    return AspectRatio(
      aspectRatio: 1.15,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: const Color(0xFFE2E8F0),
            child: InkWell(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ServiceDetailScreen(serviceId: service.id))),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Full-bleed photo.
                  thumbnailUrl != null
                      ? Image.network(
                          thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => placeholder,
                        )
                      : placeholder,
                  // Dark fade at the bottom so the white text always reads,
                  // whatever the photo looks like.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x00000000),
                          Color(0x26000000),
                          Color(0xD9000000),
                        ],
                        stops: [0.25, 0.45, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 9,
                    right: 9,
                    bottom: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          service.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            height: 1.2,
                            shadows: [
                              Shadow(color: Color(0x66000000), blurRadius: 4),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Starting at',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      height: 1.1,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  Text(
                                    '₹${service.pricing.basePrice.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      height: 1.2,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Color(0xFF16A34A),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Salon / HelpNow tabs: same layout as the home screen's top (dark header,
// location + search, hero banner) tinted in the tab's own colour, followed by
// every service in that tab's category as a two-column grid.
// ---------------------------------------------------------------------------

class SalonHomeScreen extends StatelessWidget {
  const SalonHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CategoryLanding(
      keywords: ['salon', 'saloon', 'bliss', 'beauty'],
      title: 'Salon Services',
      bannerPath: '/public/customer-app/salon-banners',
      // Soft blush theme: very light pink page and header, deep-rose text,
      // and a light banner card that blends into the banner photos' light
      // pink left side.
      accent: Color(0xFFDB2777),
      pageColor: Color(0xFFFFF0F6),
      headerColor: Color(0xFFF9D3E4),
      headerForeground: Color(0xFF831843),
      cardColor: Color(0xFFF7C6DB),
      lightCard: true,
      slides: [
        (
          tag: 'Salon at Home',
          title1: 'Beauty & Grooming',
          title2: 'At Your Doorstep',
          subtitle: 'Trained beauticians with\nhygienic, branded products.',
          image: null,
          icon: Icons.spa_rounded,
          button: 'Book a Service',
        ),
        (
          tag: 'Trending',
          title1: 'Haircut & Styling',
          title2: 'By Top Experts',
          subtitle: 'Fresh looks without\nstepping out of home.',
          image: null,
          icon: Icons.content_cut_rounded,
          button: 'Book a Service',
        ),
        (
          tag: 'Pamper Yourself',
          title1: 'Facial & Glow',
          title2: 'Relax at Home',
          subtitle: 'Skin care and spa rituals\nbooked in a few taps.',
          image: null,
          icon: Icons.face_retouching_natural_rounded,
          button: 'Book a Service',
        ),
      ],
    );
  }
}

class HelpNowHomeScreen extends StatelessWidget {
  const HelpNowHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CategoryLanding(
      keywords: ['help'],
      title: 'HelpNow Services',
      bannerPath: '/public/customer-app/helpnow-banners',
      // Yellow header (HelpNow's uniform colour) with dark text, and the
      // light banner card — the banner photos are white on the left.
      accent: Color(0xFFD97706),
      pageColor: Color(0xFFFFFBEB),
      headerColor: Color(0xFFFACC15),
      headerForeground: Color(0xFF3B2A06),
      cardColor: Color(0xFFFEF3C7),
      lightCard: true,
      slides: [
        (
          tag: 'Quick Support',
          title1: 'Instant Help',
          title2: 'In Minutes',
          subtitle: 'Verified experts at your door\nright when you need them.',
          image: null,
          icon: Icons.support_agent_rounded,
          button: 'Book a Service',
        ),
        (
          tag: 'Emergency',
          title1: 'Urgent Repairs',
          title2: 'No Long Waits',
          subtitle: 'Leaks, wiring, breakdowns —\nfixed fast and safely.',
          image: null,
          icon: Icons.bolt_rounded,
          button: 'Book a Service',
        ),
        (
          tag: 'On Demand',
          title1: 'Quick Cleaning',
          title2: 'Same Day',
          subtitle: 'Kitchen, bathroom or sofa —\ncleaned when it suits you.',
          image: null,
          icon: Icons.cleaning_services_rounded,
          button: 'Book a Service',
        ),
      ],
    );
  }
}

class _CategoryLanding extends ConsumerWidget {
  final List<String> keywords;
  final String title;
  final Color accent;
  final Color pageColor;
  final Color headerColor;
  // Top bar / location text and icons; dark when [headerColor] is light.
  final Color headerForeground;
  final Color cardColor;
  final bool lightCard;
  // Bundled slides — shown until the API answers, and if it fails or has no
  // active banners.
  final List<_HeroSlide> slides;
  // Public API path of this tab's admin-managed banners, if it has any.
  final String? bannerPath;

  const _CategoryLanding({
    required this.keywords,
    required this.title,
    required this.accent,
    this.pageColor = const Color(0xFFF8FAFC),
    required this.headerColor,
    this.headerForeground = Colors.white,
    required this.cardColor,
    this.lightCard = false,
    required this.slides,
    this.bannerPath,
  });

  List<_HeroSlide> _bannerSlides(WidgetRef ref) {
    final path = bannerPath;
    if (path == null) return slides;
    final banners = ref.watch(appBannersProvider(path)).valueOrNull;
    if (banners == null || banners.isEmpty) return slides;
    return [
      for (final b in banners)
        (
          tag: b.tagLine,
          title1: b.titleLine1,
          title2: b.titleLine2,
          subtitle: b.description,
          image: b.imageUrl,
          icon: slides.first.icon,
          button: b.buttonText,
        ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(serviceCategoriesProvider);
    final category = categories.valueOrNull
        ?.where((c) => keywords.any((k) => c.label.toLowerCase().contains(k)))
        .firstOrNull;

    return Scaffold(
      backgroundColor: pageColor,
      drawer: const AppDrawer(),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        // Dark status-bar icons over a light header, light over a dark one.
        value: headerForeground == Colors.white
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: headerColor,
                boxShadow: [
                  BoxShadow(color: headerColor, offset: const Offset(0, 1))
                ],
              ),
              child: SafeArea(
                  bottom: false,
                  child: CustomTopBar(foreground: headerForeground)),
            ),
            Expanded(
              child: RefreshIndicator(
                color: accent,
                onRefresh: () async {
                  ref.invalidate(serviceCategoriesProvider);
                  ref.invalidate(servicesByCategoryProvider);
                  if (bannerPath != null) {
                    ref.invalidate(appBannersProvider(bannerPath!));
                  }
                },
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    Container(
                      color: headerColor,
                      child: Column(
                        children: [
                          TopBarLocationSearch(foreground: headerForeground),
                          _HeroBanner(
                            slides: _bannerSlides(ref),
                            accent: accent,
                            cardColor: cardColor,
                            categoryId: category?.id,
                            lightCard: lightCard,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: headerForeground == Colors.white
                                  ? const Color(0xFF0F172A)
                                  : headerForeground,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (categories.isLoading && category == null)
                      _landingLoader(accent)
                    else if (category == null)
                      _landingEmpty(accent, '$title coming soon')
                    else
                      _CategoryServicesGrid(category: category, accent: accent),
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

class _CategoryServicesGrid extends ConsumerWidget {
  final ServiceCategory category;
  final Color accent;
  const _CategoryServicesGrid({required this.category, required this.accent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(servicesByCategoryProvider(category.id)).when(
          data: (items) {
            if (items.isEmpty) {
              return _landingEmpty(accent, 'Services coming soon');
            }
            final cardWidth = (MediaQuery.of(context).size.width - 32 - 12) / 2;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final s in items)
                    SizedBox(
                      width: cardWidth,
                      child: _ServiceGridCard(service: s, accent: accent),
                    ),
                ],
              ),
            );
          },
          loading: () => _landingLoader(accent),
          error: (err, _) => AppErrorView(
            error: err,
            compact: true,
            onRetry: () =>
                ref.invalidate(servicesByCategoryProvider(category.id)),
          ),
        );
  }
}

Widget _landingLoader(Color accent) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: accent),
        ),
      ),
    );

Widget _landingEmpty(Color accent, String text) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.hourglass_top_rounded, color: accent, size: 30),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
