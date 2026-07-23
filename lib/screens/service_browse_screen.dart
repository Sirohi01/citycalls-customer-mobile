import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/catalog_providers.dart';
import 'service_detail_screen.dart';
class ServiceBrowseScreen extends ConsumerStatefulWidget {
  const ServiceBrowseScreen({super.key});

  @override
  ConsumerState<ServiceBrowseScreen> createState() => _ServiceBrowseScreenState();
}

class _ServiceBrowseScreenState extends ConsumerState<ServiceBrowseScreen> {
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(serviceCategoriesProvider);
    final services = ref.watch(servicesByCategoryProvider(_selectedCategoryId));

    return Scaffold(
      appBar: AppBar(title: const Text('Browse Services')),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: categories.when(
              data: (cats) => ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: const Text('All'),
                      selected: _selectedCategoryId == null,
                      onSelected: (_) => setState(() => _selectedCategoryId = null),
                    ),
                  ),
                  ...cats.map((c) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(c.label),
                          selected: _selectedCategoryId == c.id,
                          onSelected: (_) => setState(() => _selectedCategoryId = c.id),
                        ),
                      )),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Failed to load categories: $err')),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: services.when(
              data: (items) => items.isEmpty
                  ? const Center(child: Text('No services available in this category yet.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final service = items[index];
                        return Card(
                          child: ListTile(
                            title: Text(service.name),
                            subtitle: Text('Starting at ₹${service.pricing.basePrice.toStringAsFixed(0)} · ~${service.expectedDurationMinutes} min'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => ServiceDetailScreen(serviceId: service.id)),
                            ),
                          ),
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Failed to load services: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
