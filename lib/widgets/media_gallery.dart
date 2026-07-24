import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/media_models.dart';
import '../theme/app_theme.dart';

// Displays a Catalog Service's CATALOG_IMAGE/VIDEO attachments — the
// customer-facing counterpart to citycalls-admin-web's MediaGallery.tsx,
// same underlying Files entity-attachment system (entityType: 'SERVICE').
class MediaGallerySection extends StatelessWidget {
  final List<MediaFile> media;
  final String Function(MediaFile) resolveUrl;
  const MediaGallerySection({super.key, required this.media, required this.resolveUrl});

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) return const SizedBox.shrink();
    final images = media.where((f) => !f.isVideo).toList();
    final videos = media.where((f) => f.isVideo).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images.isNotEmpty) _ImageCarousel(images: images, resolveUrl: resolveUrl),
        if (videos.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Videos', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: videos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) => _VideoTile(url: resolveUrl(videos[i])),
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ImageCarousel extends StatefulWidget {
  final List<MediaFile> images;
  final String Function(MediaFile) resolveUrl;
  const _ImageCarousel({required this.images, required this.resolveUrl});

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (i) => setState(() => _index = i),
              itemCount: widget.images.length,
              itemBuilder: (context, i) => Image.network(
                widget.resolveUrl(widget.images[i]),
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(color: AppColors.neutral100, child: const Icon(Icons.broken_image_outlined, color: AppColors.neutral500)),
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
        ),
        if (widget.images.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.images.length,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _index ? AppColors.black : AppColors.neutral200,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _VideoTile extends StatefulWidget {
  final String url;
  const _VideoTile({required this.url});

  @override
  State<_VideoTile> createState() => _VideoTileState();
}

class _VideoTileState extends State<_VideoTile> {
  late final VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() => _ready = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 160,
        height: 180,
        child: !_ready
            ? Container(color: AppColors.neutral100, child: const Center(child: CircularProgressIndicator()))
            : GestureDetector(
                onTap: () => setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play()),
                child: Stack(
                  alignment: Alignment.center,
                  fit: StackFit.expand,
                  children: [
                    FittedBox(fit: BoxFit.cover, child: SizedBox(width: _controller.value.size.width, height: _controller.value.size.height, child: VideoPlayer(_controller))),
                    if (!_controller.value.isPlaying)
                      Container(
                        decoration: const BoxDecoration(color: Colors.black26),
                        child: const Icon(Icons.play_circle_fill, color: Colors.white, size: 44),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
