import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import 'glow_blob.dart';

// Shared chrome for the Onboarding flow's screens (OTP request/verify) —
// mirrors citycalls-admin-web's /login page: dark slate gradient, two soft
// brand-tinted glow blobs, the wordmark top-left, and a frosted glass card
// for the actual form. Kept as one shared widget rather than duplicated
// per-screen so the two screens can't visually drift apart.
class AuthBackground extends StatelessWidget {
  final Widget child;
  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate950,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.slate950,
                  AppColors.slate900,
                  AppColors.slate950
                ],
              ),
            ),
          ),
          const Positioned(
              left: -80,
              top: 220,
              child: GlowBlob(color: AppColors.lime500, size: 320)),
          const Positioned(
              right: -100,
              top: 40,
              child: GlowBlob(color: AppColors.indigo500, size: 260)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset('assets/images/logo.png',
                          height: 96, fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 28),
                    _GlassCard(child: child),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: child,
        ),
      ),
    );
  }
}

// Shared field styling for the dark glass card — outlined, translucent,
// lime focus ring, matching the Input classes in admin-web's login page.
InputDecoration authFieldDecoration(
    {required String label,
    IconData? icon,
    String? prefixText,
    String? errorText}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppColors.slate300),
    prefixIcon:
        icon != null ? Icon(icon, color: AppColors.slate400, size: 20) : null,
    prefixText: prefixText,
    prefixStyle: const TextStyle(color: AppColors.slate200),
    errorText: errorText,
    errorStyle: const TextStyle(color: AppColors.red400),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.05),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.lime400, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.red400),
    ),
  );
}

ButtonStyle authButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: AppColors.lime500,
    foregroundColor: AppColors.slate950,
    minimumSize: const Size.fromHeight(48),
    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );
}
