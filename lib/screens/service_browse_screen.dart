import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/catalog_models.dart';
import '../providers/catalog_providers.dart';
import 'service_detail_screen.dart';

class ServiceBrowseScreen extends ConsumerStatefulWidget {
  final String? initialCategoryId;
  final String title;
  final VoidCallback? onBack;
  const ServiceBrowseScreen({super.key, this.initialCategoryId, this.title = 'All Categories', this.onBack});

  @override
  ConsumerState<ServiceBrowseScreen> createState() => _ServiceBrowseScreenState();
}

class _ServiceBrowseScreenState extends ConsumerState<ServiceBrowseScreen> {
  late String? _selectedCategoryId = widget.initialCategoryId;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(serviceCategoriesProvider);
    final services = ref.watch(servicesByCategoryProvider(_selectedCategoryId));

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Stack(
        children: [
          // Background Gradient matching the UI
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF6EAF6), // Soft purple/pink glow top-left
                    Color(0xFFECF1FD), // Soft blue glow top-right
                    Color(0xFFF9FAFB), // Fade to normal background
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
                // Custom Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  if (widget.onBack != null || Navigator.canPop(context))
                    GestureDetector(
                      onTap: () {
                        if (widget.onBack != null) {
                          widget.onBack!();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: const Icon(Icons.arrow_back, color: Colors.black87),
                    ),
                  if (widget.onBack != null || Navigator.canPop(context))
                    const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Text(
                          'Find the best service for your home',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Icon(Icons.notifications_none, size: 22, color: Colors.black87),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search Bar & Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                        decoration: InputDecoration(
                          hintText: 'Search for a service...',
                          hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                          prefixIcon: const Icon(Icons.search, color: Colors.black45, size: 20),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () => setState(() {
                                    _searchController.clear();
                                    _query = '';
                                  }),
                                ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Icon(Icons.tune, color: Colors.black87, size: 20),
                  ),
                ],
              ),
            ),

            // Category Chips
            if (widget.initialCategoryId == null)
              SizedBox(
                height: 44,
                child: categories.when(
                  data: (cats) => ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    children: [
                      _CategoryChip(
                        label: 'All',
                        selected: _selectedCategoryId == null,
                        icon: Icons.grid_view_rounded,
                        onTap: () => setState(() => _selectedCategoryId = null),
                      ),
                      ...cats.map((c) => _CategoryChip(
                            label: c.label,
                            selected: _selectedCategoryId == c.id,
                            icon: _getCategoryIcon(c.label),
                            iconColor: _getCategoryColor(c.label),
                            onTap: () => setState(() => _selectedCategoryId = c.id),
                          )),
                    ],
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Failed to load categories: $err')),
                ),
              ),

            // Main Content Area (Banner + List)
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // Promo Banner (Commented out as requested)
                  /*
                  if (_query.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE8F1FC), Color(0xFFD0E1FA)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Professional Services\nYou Can Trust',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F3B77),
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Verified experts • On-time service\n• 100% Satisfaction',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF3B5B8A),
                                        height: 1.3,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1973E8),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('Book Now', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                                          SizedBox(width: 4),
                                          Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  height: 80,
                                  alignment: Alignment.centerRight,
                                  child: const Icon(Icons.handyman, size: 70, color: Color(0xFF1973E8)), // Placeholder for the actual image
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  */

                  // Service List
                  SliverToBoxAdapter(
                    child: services.when(
                      data: (allItems) {
                        final items = _query.isEmpty ? allItems : allItems.where((s) => s.name.toLowerCase().contains(_query)).toList();
                        return items.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Text(
                                    _query.isEmpty ? 'No services available in this category yet.' : 'No services match "$_query".',
                                    style: const TextStyle(color: Colors.black45),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                itemCount: items.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) => _ServiceCard(service: items[index]),
                              );
                      },
                      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator())),
                      error: (err, _) => Center(child: Text('Failed to load services: $err')),
                    ),
                  ),

                  // Bottom Info Banner
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _BottomInfoItem(icon: Icons.verified_user, color: Colors.blue, text: 'Trusted\nProfessionals'),
                            _BottomInfoItem(icon: Icons.stars, color: Colors.green, text: 'On-Time\nService'),
                            _BottomInfoItem(icon: Icons.thumb_up, color: Colors.purple, text: 'Satisfaction\nGuaranteed'),
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
      ),
        ],
      ),
    );
  }
}

class _BottomInfoItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _BottomInfoItem({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
      ],
    );
  }
}

IconData _getCategoryIcon(String label) {
  final l = label.toLowerCase();
  if (l.contains('ac')) return Icons.ac_unit;
  if (l.contains('clean')) return Icons.cleaning_services;
  if (l.contains('pest') || l.contains('bug')) return Icons.pest_control;
  if (l.contains('paint')) return Icons.format_paint;
  if (l.contains('salon') || l.contains('beauty')) return Icons.face;
  return Icons.handyman;
}

Color _getCategoryColor(String label) {
  final l = label.toLowerCase();
  if (l.contains('ac')) return Colors.blue;
  if (l.contains('clean')) return Colors.green;
  if (l.contains('pest') || l.contains('bug')) return Colors.purple;
  if (l.contains('paint')) return Colors.orange;
  if (l.contains('salon') || l.contains('beauty')) return Colors.pink;
  return Colors.teal;
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
        return images.isEmpty ? null : catalogRepo.resolveMediaUrl(images.first);
      },
      orElse: () => null,
    );
    
    final themeColor = _getCategoryColor(service.name);
    final themeIcon = _getCategoryIcon(service.name);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ServiceDetailScreen(serviceId: service.id))),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: thumbnailUrl != null
                          ? Image.network(
                              thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(themeIcon, color: themeColor, size: 28),
                              loadingBuilder: (context, child, progress) => progress == null ? child : Icon(themeIcon, color: themeColor, size: 28),
                            )
                          : Icon(themeIcon, color: themeColor, size: 28),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: themeColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(themeIcon, size: 10, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name, 
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87), 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 12, color: Colors.black45),
                        const SizedBox(width: 4),
                        Text(
                          '~${service.expectedDurationMinutes} min', 
                          style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w500)
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Starting at', style: TextStyle(color: Colors.black38, fontSize: 9, fontWeight: FontWeight.w600)),
                            Text(
                              '₹${service.pricing.basePrice.toStringAsFixed(0)}', 
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: themeColor)
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: themeColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.arrow_forward, color: themeColor, size: 16),
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
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label, 
    required this.selected, 
    this.icon, 
    this.iconColor, 
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1973E8) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? const Color(0xFF1973E8) : Colors.grey.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon, 
                  size: 16, 
                  color: selected ? Colors.white : (iconColor ?? Colors.black54)
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

