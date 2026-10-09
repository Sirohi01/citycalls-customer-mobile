import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/intro_storage.dart';
import '../providers/auth_providers.dart';
import 'otp_request_screen.dart';
import 'profile_setup_screen.dart';
import 'main_shell.dart';
import 'splash2_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  // main.dart's global sessionExpired listener checks this before redirecting
  // — without it, a fresh install with no refresh token fails getMyProfile()
  // almost instantly, and that listener yanks SplashScreen off the navigator
  // well before its own minDisplay wait in _resolveDestination below, so the
  // splash barely flashes on screen.
  static bool bootstrapping = true;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _logoSlide;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    // Logo rises up as if emerging from behind the bottom edge.
    _logoSlide = Tween<Offset>(begin: const Offset(0, 0.8), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic)));
    // Tagline drifts up from below and fades in after the logo settles.
    _taglineSlide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic)));
    _taglineFade = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut));

    // Add delay so animation doesn't finish while app is still loading
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _controller.forward();
    });

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
    // Intro (splash2-4) is shown once; a valid session also implies it was
    // already seen (covers users who updated from a build without the flag).
    var skipIntro = await IntroStorage.isSeen();
    try {
      final customer = await ref
          .read(customerRepositoryProvider)
          .getMyProfile()
          .timeout(const Duration(seconds: 8));
      destination = customer.needsProfileSetup
          ? const ProfileSetupScreen()
          : const MainShell();
      skipIntro = true;
    } catch (_) {
      // A saved session survives a slow or offline start: ApiClient only
      // deletes the tokens when the server actually rejects the session, so
      // if they are still here the failure was the network — stay logged in
      // and let the screens show their own retry. No tokens → log in.
      final stillLoggedIn =
          await ref.read(apiClientProvider).readRefreshToken() != null;
      destination =
          stillLoggedIn ? const MainShell() : const OtpRequestScreen();
      if (stillLoggedIn) skipIntro = true;
    }

    const minDisplay = Duration(seconds: 6);
    final remaining = minDisplay - stopwatch.elapsed;
    if (remaining > Duration.zero) await Future.delayed(remaining);

    SplashScreen.bootstrapping = false;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
          builder: (_) =>
              skipIntro ? destination : Splash2Screen(nextScreen: destination)),
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
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SlideTransition(
                      position: _logoSlide,
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SlideTransition(
                      position: _taglineSlide,
                      child: FadeTransition(
                        opacity: _taglineFade,
                        child: RichText(
                          text: const TextSpan(children: [
                            TextSpan(
                                text: 'Built for brand services. ',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                            // TextSpan(text: 'On Call.', style: TextStyle(color: AppColors.lime500, fontSize: 16, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
