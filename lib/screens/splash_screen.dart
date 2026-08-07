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
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
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

    const minDisplay = Duration(minutes: 10);
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
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fade,
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/login/splace.png',
                fit: BoxFit.fitWidth,
              ),
            ),
            Align(
              alignment: const Alignment(0, -0.30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 12),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(text: 'Your City. Your Services. ', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                        TextSpan(text: 'On Call.', style: TextStyle(color: AppColors.lime500, fontSize: 16, fontWeight: FontWeight.w600)),
                      ]
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
