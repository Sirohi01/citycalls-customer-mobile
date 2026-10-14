import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/catalog_models.dart';
import '../providers/catalog_providers.dart';
import '../widgets/state_views.dart';
import 'notifications_screen.dart';
import 'service_detail_screen.dart';

class ServiceBrowseScreen extends ConsumerStatefulWidget {
  final String? initialCategoryId;
  final String title;
  final VoidCallback? onBack;
  final String? initialQuery;

  const ServiceBrowseScreen({
    super.key,
    this.initialCategoryId,
    this.title = 'Explore Services',
    this.onBack,
    this.initialQuery,
  });

  @override
  ConsumerState<ServiceBrowseScreen> createState() =>
      _ServiceBrowseScreenState();
}

class _ServiceBrowseScreenState extends ConsumerState<ServiceBrowseScreen> {
  late String? _selectedCategoryId = widget.initialCategoryId;
  late final _searchController =
      TextEditingController(text: widget.initialQuery?.trim() ?? '');
  late String _query = (widget.initialQuery ?? '').trim().toLowerCase();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(serviceCategoriesProvider);
    final isSearching = _query.isNotEmpty;
    final services = ref.watch(
        servicesByCategoryProvider(isSearching ? null : _selectedCategoryId));
    final canGoBack = widget.onBack != null || Navigator.canPop(context);
    final categoryList = categories.valueOrNull ?? const <ServiceCategory>[];
    final selectedCategory = _findCategory(categoryList, _selectedCategoryId);
    final isCategoryPage = widget.initialCategoryId != null;
    final headerTitle = isCategoryPage
        ? selectedCategory?.label ?? 'Services'
        : 'Explore Services';
    final headerSubtitle = isSearching
        ? 'Searching across all categories'
        : isCategoryPage
            ? 'Choose the right ${selectedCategory?.label.toLowerCase() ?? 'service'} option'
            : 'Professional help for your home';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 370,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFEAF7EF),
                    Color(0xFFF5FBF7),
                    Color(0xFFF6F8FA)
                  ],
                  stops: [0, 0.55, 1],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                  child: Row(
                    children: [
                      if (canGoBack) ...[
                        _IconButtonShell(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => widget.onBack != null
                              ? widget.onBack!()
                              : Navigator.pop(context),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              headerTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              headerSubtitle,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      _IconButtonShell(
                        icon: Icons.notifications_none_rounded,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const NotificationsScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.035),
                            blurRadius: 14,
                            offset: const Offset(0, 6))
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onChanged: (v) =>
                          setState(() => _query = v.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: 'Search AC, cleaning, pest control...',
                        hintStyle: const TextStyle(
                            color: Color(0xFF94A3B8), fontSize: 13.5),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: Color(0xFF64748B), size: 21),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () => setState(() {
                                  _searchController.clear();
                                  _query = '';
                                }),
                              ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      if (_query.isEmpty && widget.initialCategoryId == null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 8, 0, 14),
                            child: categories.when(
                              data: (cats) => _CategoryImageRail(
                                categories: cats,
                                selectedCategoryId: _selectedCategoryId,
                                onSelect: (id) =>
                                    setState(() => _selectedCategoryId = id),
                              ),
                              loading: () => const SizedBox(
                                  height: 132,
                                  child: Center(
                                      child: CircularProgressIndicator())),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                          child: _CatalogSummary(
                            isSearching: isSearching,
                            selectedCategoryId: _selectedCategoryId,
                            categories: categoryList,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: services.when(
                          data: (allItems) {
                            final categoryLabels = {
                              for (final category in categoryList)
                                category.id: category.label.toLowerCase(),
                            };
                            final tokens = _query
                                .split(RegExp(r'\s+'))
                                .where((part) => part.isNotEmpty)
                                .toList();
                            final items = tokens.isEmpty
                                ? allItems
                                : allItems.where((service) {
                                    final haystack = [
                                      service.name,
                                      service.description ?? '',
                                      categoryLabels[service.categoryId] ?? '',
                                    ].join(' ').toLowerCase();
                                    return tokens.every(haystack.contains);
                                  }).toList();
                            return items.isEmpty
                                ? AppEmptyView(
                                    icon: _query.isEmpty
                                        ? Icons.home_repair_service_outlined
                                        : Icons.search_off_rounded,
                                    title: _query.isEmpty
                                        ? 'Nothing here yet'
                                        : 'No match for "$_query"',
                                    subtitle: _query.isEmpty
                                        ? 'This category has no services listed right now.'
                                        : 'Try a shorter word, or browse the categories above.',
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    itemCount: items.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) =>
                                        _ServiceCard(service: items[index]),
                                  );
                          },
                          loading: () => const Center(
                              child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: CircularProgressIndicator())),
                          error: (err, _) => AppErrorView(
                            error: err,
                            onRetry: () => ref.invalidate(
                                servicesByCategoryProvider(
                                    isSearching ? null : _selectedCategoryId)),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 18, 16, 24),
                          child: _TrustStrip(),
                        ),
                      ),
                    ],
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

class _IconButtonShell extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButtonShell({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Stack(
          children: [
            Container(
              height: 48,
              width: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.035),
                      blurRadius: 12,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Icon(icon, color: const Color(0xFF0F172A), size: 21),
            ),
          ],
        ),
      ),
    );
  }
}

ServiceCategory? _findCategory(List<ServiceCategory> categories, String? id) {
  if (id == null) return null;
  for (final category in categories) {
    if (category.id == id) return category;
  }
  return null;
}

class _CategoryImageRail extends StatelessWidget {
  final List<ServiceCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelect;

  const _CategoryImageRail(
      {required this.categories,
      required this.selectedCategoryId,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const maxItems = 5;
    final items = categories.take(maxItems).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Our Categories',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _CategoryImageCard(
                  category: items[i],
                  index: i,
                  selected: selectedCategoryId == items[i].id,
                  onTap: () => onSelect(
                      selectedCategoryId == items[i].id ? null : items[i].id),
                ),
                if (i != items.length - 1) const SizedBox(width: 5),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryImageCard extends ConsumerWidget {
  final ServiceCategory category;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryImageCard({
    required this.category,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = (MediaQuery.of(context).size.width - 32 - 4 * 5) / 5;
    final color = _categoryIconColors[index % _categoryIconColors.length];
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 66,
              width: width,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                    color: selected ? color : color.withValues(alpha: 0.16),
                    width: selected ? 1.5 : 1),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withValues(alpha: selected ? 0.08 : 0.045),
                    blurRadius: selected ? 16 : 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Center(
                child: ref.watch(masterMediaProvider(category.id)).when(
                      data: (media) {
                        String? url;
                        for (final file in media) {
                          if (!file.isVideo &&
                              file.category == 'CATALOG_IMAGE') {
                            url = ref
                                .read(catalogRepositoryProvider)
                                .resolveMediaUrl(file);
                            break;
                          }
                        }
                        url ??= media.where((m) => !m.isVideo).isEmpty
                            ? null
                            : ref
                                .read(catalogRepositoryProvider)
                                .resolveMediaUrl(
                                    media.where((m) => !m.isVideo).first);
                        if (url != null) {
                          return Image.network(
                            url,
                            width: width,
                            height: 66,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                                _getCategoryIcon(category.label),
                                color: color,
                                size: 32),
                          );
                        }
                        return Icon(_getCategoryIcon(category.label),
                            color: color, size: 32);
                      },
                      loading: () => SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: color)),
                      error: (_, __) => Icon(_getCategoryIcon(category.label),
                          color: color, size: 32),
                    ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              category.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.8,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                height: 1.08,
                color: selected ? color : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _categoryIconColors = [
  Color(0xFF2563EB),
  Color(0xFF16A34A),
  Color(0xFF9333EA),
  Color(0xFFF97316),
  Color(0xFFDB2777),
];

class _CatalogSummary extends StatelessWidget {
  final bool isSearching;
  final String? selectedCategoryId;
  final List<ServiceCategory> categories;

  const _CatalogSummary(
      {required this.isSearching,
      required this.selectedCategoryId,
      required this.categories});

  @override
  Widget build(BuildContext context) {
    ServiceCategory? selected;
    for (final category in categories) {
      if (category.id == selectedCategoryId) {
        selected = category;
        break;
      }
    }
    final title =
        isSearching ? 'Search results' : selected?.label ?? 'All Services';
    final subtitle = isSearching
        ? 'Best matches from every category'
        : selected == null
            ? 'Browse every available CityCalls service'
            : 'Handpicked services in this category';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(999)),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user_outlined,
                  size: 14, color: Color(0xFF2563EB)),
              SizedBox(width: 5),
              Text('Verified',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2563EB))),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _BottomInfoItem(
              icon: Icons.verified_user,
              color: Color(0xFF2563EB),
              text: 'Verified\nPros'),
          _BottomInfoItem(
              icon: Icons.schedule_rounded,
              color: Color(0xFF16A34A),
              text: 'On-time\nVisit'),
          _BottomInfoItem(
              icon: Icons.payments_outlined,
              color: Color(0xFFF97316),
              text: 'Clear\nPricing'),
        ],
      ),
    );
  }
}

class _BottomInfoItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _BottomInfoItem(
      {required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 19),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                height: 1.1)),
      ],
    );
  }
}

IconData _getCategoryIcon(String label) {
  final l = label.toLowerCase();
  if (l.contains('ac')) {
    return Icons.ac_unit_rounded;
  }
  if (l.contains('clean')) {
    return Icons.cleaning_services_rounded;
  }
  if (l.contains('pest') || l.contains('bug')) {
    return Icons.pest_control_rounded;
  }
  if (l.contains('paint')) {
    return Icons.format_paint_rounded;
  }
  if (l.contains('salon') || l.contains('beauty')) {
    return Icons.face_retouching_natural_rounded;
  }
  if (l.contains('wash')) {
    return Icons.local_laundry_service_rounded;
  }
  return Icons.handyman_rounded;
}

Color _getCategoryColor(String label) {
  final l = label.toLowerCase();
  if (l.contains('ac') || l.contains('appliance')) {
    return const Color(0xFF2563EB);
  }
  if (l.contains('clean')) {
    return const Color(0xFF16A34A);
  }
  if (l.contains('pest') || l.contains('bug')) {
    return const Color(0xFF7C3AED);
  }
  if (l.contains('paint')) {
    return const Color(0xFFF97316);
  }
  if (l.contains('salon') || l.contains('beauty')) {
    return const Color(0xFFDB2777);
  }
  return const Color(0xFF0F766E);
}

class _ServiceCard extends ConsumerWidget {
  final Service service;
  const _ServiceCard({required this.service});

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
    final themeColor = _getCategoryColor(service.name);
    final themeIcon = _getCategoryIcon(service.name);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ServiceDetailScreen(serviceId: service.id))),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 5))
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 96,
                height: 72,
                decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(15)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: thumbnailUrl != null
                      ? Image.network(
                          thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Icon(themeIcon, color: themeColor, size: 34),
                          loadingBuilder: (context, child, progress) =>
                              progress == null
                                  ? child
                                  : Icon(themeIcon,
                                      color: themeColor, size: 34),
                        )
                      : Icon(themeIcon, color: themeColor, size: 34),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Color(0xFF0F172A),
                            height: 1.2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 14, color: themeColor),
                        const SizedBox(width: 5),
                        Text('~${service.expectedDurationMinutes} min',
                            style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 10),
                        const Icon(Icons.verified_rounded,
                            size: 14, color: Color(0xFF16A34A)),
                        const SizedBox(width: 4),
                        const Expanded(
                            child: Text('Verified',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600))),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                color: Color(0xFF64748B), fontSize: 11),
                            children: [
                              const TextSpan(text: 'Starts at '),
                              TextSpan(
                                text:
                                    '₹${service.pricing.basePrice.toStringAsFixed(0)}',
                                style: TextStyle(
                                    color: themeColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                              color: themeColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle),
                          child: Icon(Icons.arrow_forward_rounded,
                              color: themeColor, size: 18),
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
    );
  }
}
