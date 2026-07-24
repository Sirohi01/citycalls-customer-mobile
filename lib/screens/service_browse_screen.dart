import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/catalog_models.dart';
import '../providers/catalog_providers.dart';
import '../theme/app_theme.dart';
import 'service_detail_screen.dart';

// Per docs/rohit/05-customer-app-screen-list.md "Home" — Service Category
// Browse. Category selection filters the service list client-side via
// servicesByCategoryProvider's family key, no extra round-trip when the
// categories themselves are already loaded.
class ServiceBrowseScreen extends ConsumerStatefulWidget {
  final String? initialCategoryId;
  const ServiceBrowseScreen({super.key, this.initialCategoryId});

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
      backgroundColor: AppColors.neutral100,
      appBar: AppBar(
        title: const Text('Browse Services'),
        centerTitle: false,
        backgroundColor: AppColors.neutral100,
        surfaceTintColor: AppColors.neutral100,
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search for a service...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _query = '';
                        }),
                      ),
                filled: true,
                fillColor: AppColors.neutral100,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Container(
            color: AppColors.white,
            child: SizedBox(
              height: 56,
              child: categories.when(
                data: (cats) => ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    _CategoryChip(label: 'All', selected: _selectedCategoryId == null, onTap: () => setState(() => _selectedCategoryId = null)),
                    ...cats.map((c) => _CategoryChip(
                          label: c.label,
                          selected: _selectedCategoryId == c.id,
                          onTap: () => setState(() => _selectedCategoryId = c.id),
                        )),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Failed to load categories: $err')),
              ),
            ),
          ),
          Expanded(
            child: services.when(
              data: (allItems) {
                final items = _query.isEmpty ? allItems : allItems.where((s) => s.name.toLowerCase().contains(_query)).toList();
                return items.isEmpty
                    ? Center(
                        child: Text(
                          _query.isEmpty ? 'No services available in this category yet.' : 'No services match "$_query".',
                          style: const TextStyle(color: AppColors.neutral500),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) => _ServiceCard(service: items[index]),
                      );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Failed to load services: $err')),
            ),
          ),
        ],
      ),
    );
  }
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

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ServiceDetailScreen(serviceId: service.id))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: thumbnailUrl != null
                      ? Image.network(
                          thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const _ServicePlaceholderIcon(),
                          loadingBuilder: (context, child, progress) => progress == null ? child : const _ServicePlaceholderIcon(),
                        )
                      : const _ServicePlaceholderIcon(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 13, color: AppColors.neutral500),
                        const SizedBox(width: 4),
                        Text('~${service.expectedDurationMinutes} min', style: const TextStyle(color: AppColors.neutral500, fontSize: 12)),
                        if (service.warrantyPeriodDays > 0) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.verified_outlined, size: 13, color: AppColors.neutral500),
                          const SizedBox(width: 4),
                          Text('${service.warrantyPeriodDays}d warranty', style: const TextStyle(color: AppColors.neutral500, fontSize: 12)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Starting at', style: TextStyle(color: AppColors.neutral500, fontSize: 10.5)),
                            Text('₹${service.pricing.basePrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: AppColors.black, shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
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

class _ServicePlaceholderIcon extends StatelessWidget {
  const _ServicePlaceholderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.neutral100,
      child: const Icon(Icons.build_outlined, color: AppColors.neutral500, size: 28),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.black,
        backgroundColor: AppColors.neutral100,
        labelStyle: TextStyle(color: selected ? Colors.white : AppColors.black, fontWeight: FontWeight.w500),
        side: BorderSide.none,
        showCheckmark: false,
      ),
    );
  }
}
