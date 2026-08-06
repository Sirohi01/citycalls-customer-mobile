import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import 'glow_blob.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;
  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate950,
      body: Stack(
        children: [
          // Deep rich background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF020617), // slate-950
                  Color(0xFF0F172A), // slate-900
                  Color(0xFF020617), // slate-950
                ],
              ),
            ),
          ),
          // Subtle ambient glow
          const Positioned(
              left: -120,
              top: 200,
              child: GlowBlob(color: Color(0x1A84CC16), size: 400)), // Lime glow, reduced opacity
          const Positioned(
              right: -150,
              top: 50,
              child: GlowBlob(color: Color(0x1A6366F1), size: 350)), // Indigo glow, reduced opacity
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sleek Logo Presentation
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ]
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset('assets/images/logo.png',
                            height: 72, fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(height: 36),
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
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              )
            ]
          ),
          child: child,
        ),
      ),
    );
  }
}

InputDecoration authFieldDecoration(
    {required String label,
    IconData? icon,
    String? prefixText,
    String? errorText}) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: AppColors.slate300.withValues(alpha: 0.8), fontSize: 14),
    prefixIcon: icon != null 
        ? Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(icon, color: AppColors.slate400, size: 22),
          ) 
        : null,
    prefixText: prefixText,
    prefixStyle: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600, fontSize: 15),
    errorText: errorText,
    errorStyle: const TextStyle(color: AppColors.red400, fontWeight: FontWeight.w500),
    filled: true,
    fillColor: Colors.black.withValues(alpha: 0.2),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.lime400, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.red400, width: 1.5),
    ),
  );
}

ButtonStyle authButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: AppColors.lime500,
    foregroundColor: AppColors.slate950,
    elevation: 4,
    shadowColor: AppColors.lime500.withValues(alpha: 0.4),
    padding: const EdgeInsets.symmetric(vertical: 16),
    textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );
}
