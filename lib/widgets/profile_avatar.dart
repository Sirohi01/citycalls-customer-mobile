import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/customer_providers.dart';

/// The customer's profile photo, falling back to the first letter of their
/// name on a green circle when no photo is set (or it fails to load).
class ProfileAvatar extends ConsumerWidget {
  final double size;
  final double borderWidth;
  final Color borderColor;

  const ProfileAvatar({
    super.key,
    required this.size,
    this.borderWidth = 0,
    this.borderColor = Colors.white,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(myProfileProvider).valueOrNull?.name ?? '';
    final photoUrl = ref.watch(profilePhotoUrlProvider).valueOrNull;

    final initial = Container(
      color: const Color(0xFF0F5132),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderWidth > 0
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
      ),
      child: ClipOval(
        child: photoUrl == null
            ? initial
            : Image.network(
                photoUrl,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (_, __, ___) => initial,
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : initial,
              ),
      ),
    );
  }
}
