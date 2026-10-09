import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/catalog_models.dart';
import '../providers/catalog_providers.dart';
import '../providers/favourites_providers.dart';
import '../widgets/state_views.dart';
import 'home_screen.dart' show formatServiceDuration;
import 'service_browse_screen.dart';
import 'service_detail_screen.dart';

const _kGreen = Color(0xFF16A34A);
const _kHeart = Color(0xFFEF4444);

class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favourites = ref.watch(favouritesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'My Favourites',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: favourites.when(
                data: (ids) {
                  if (ids.isEmpty) return const _EmptyFavourites();
                  final list = ids.toList();
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _FavouriteTile(serviceId: list[i]),
                  );
                },
                loading: () => const Center(
                    child: CircularProgressIndicator(color: _kGreen)),
                error: (err, _) => Center(
                  child: AppErrorView(
                    error: err,
                    onRetry: () => ref.invalidate(favouritesProvider),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavouriteTile extends ConsumerWidget {
  final String serviceId;
  const _FavouriteTile({required this.serviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(serviceDetailProvider(serviceId)).when(
          data: (s) => _tile(context, ref, s),
          loading: () => Container(
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          // Service was deleted or is unreachable — let the customer drop it.
          error: (_, __) => _shell(
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'This service is no longer available',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      ref.read(favouritesProvider.notifier).toggle(serviceId),
                  child: const Text('Remove'),
                ),
              ],
            ),
          ),
        );
  }

  Widget _tile(BuildContext context, WidgetRef ref, Service s) {
    final repo = ref.read(catalogRepositoryProvider);
    final thumb = ref.watch(serviceMediaProvider(s.id)).maybeWhen(
          data: (files) {
            final images = files.where((f) => !f.isVideo);
            return images.isEmpty ? null : repo.resolveMediaUrl(images.first);
          },
          orElse: () => null,
        );
    const placeholder = Icon(Icons.home_repair_service_rounded,
        color: Color(0xFF86EFAC), size: 30);

    return _shell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ServiceDetailScreen(serviceId: s.id))),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: thumb == null
                ? placeholder
                : Image.network(thumb,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => placeholder),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '₹${s.pricing.basePrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _kGreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.schedule_rounded,
                        size: 13, color: Color(0xFF64748B)),
                    const SizedBox(width: 3),
                    Text(
                      formatServiceDuration(s.expectedDurationMinutes),
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove from favourites',
            onPressed: () => ref.read(favouritesProvider.notifier).toggle(s.id),
            icon: const Icon(Icons.favorite_rounded, color: _kHeart),
          ),
        ],
      ),
    );
  }

  Widget _shell({required Widget child, VoidCallback? onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _EmptyFavourites extends StatelessWidget {
  const _EmptyFavourites();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _kHeart.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_border_rounded,
                  color: _kHeart, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'No favourites yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap the ♡ on any service to save it here for quick booking.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              // push, not pushReplacement, so back returns here.
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ServiceBrowseScreen())),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Browse services'),
            ),
          ],
        ),
      ),
    );
  }
}
