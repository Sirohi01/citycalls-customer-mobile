import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/glow_blob.dart';
import 'otp_request_screen.dart';
import 'profile_setup_screen.dart';
import 'main_shell.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.95, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
    _resolveDestination();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _resolveDestination() async {
    final stopwatch = Stopwatch()..start();
    Widget destination;
    try {
      final customer =
          await ref.read(customerRepositoryProvider).getMyProfile();
      destination = customer.needsProfileSetup
          ? const ProfileSetupScreen()
          : const MainShell();
    } catch (_) {
      destination = const OtpRequestScreen();
    }

    const minDisplay = Duration(milliseconds: 1500);
    final remaining = minDisplay - stopwatch.elapsed;
    if (remaining > Duration.zero) await Future.delayed(remaining);

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate950,
      body: Stack(
        children: [
          // Premium deep background
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
              child: GlowBlob(color: Color(0x1A84CC16), size: 400)), // Lime glow
          const Positioned(
              right: -150,
              top: 50,
              child: GlowBlob(color: Color(0x1A6366F1), size: 350)), // Indigo glow
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo Box with subtle glassmorphism
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          )
                        ]
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset('assets/images/logo.png',
                            height: 110, fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'CityCalls',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Home services, sorted.',
                      style:
                          TextStyle(color: AppColors.slate400, fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 48),
                    const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: AppColors.lime400),
                    ),
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
