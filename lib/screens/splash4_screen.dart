import 'package:flutter/material.dart';
import '../data/intro_storage.dart';
import '../theme/app_theme.dart';

class Splash4Screen extends StatefulWidget {
  final Widget nextScreen;
  const Splash4Screen({super.key, required this.nextScreen});

  @override
  State<Splash4Screen> createState() => _Splash4ScreenState();
}

class _Splash4ScreenState extends State<Splash4Screen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(minutes: 10), _goNext);
  }

  void _goNext() {
    IntroStorage.markSeen();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => widget.nextScreen),
      (route) => false,
    );
  }

  // Splash3Screen pushes (not replaces) this route, so this pops right back
  // to it.
  void _goPrevious() {
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                children: [
                  const SizedBox(height: 56),
                  Image.asset(
                    'assets/images/logo.png',
                    height: 48,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  const Text('Quick Booking,',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  const Text('Easy & Fast',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.lime500)),
                ],
              ),
            ),
            // Center Image — splace4_dark.png is a background-removed cutout
            // of splace4.png (which has an opaque white/light-green
            // background, wrong for a black scaffold) with a soft green
            // glow behind it, matching splash3_screen.dart's treatment.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.lime500.withValues(alpha: 0.35),
                              AppColors.lime500.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                      // Scaled down a little so the illustration doesn't crowd the
                      // heading and buttons.
                      FractionallySizedBox(
                        widthFactor: 0.85,
                        heightFactor: 0.85,
                        child: Image.asset(
                          'assets/login/splace4_dark.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Book in just a few taps and relax,\nwe\'ll take care of the rest.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.slate400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: _goPrevious,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.slate700),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_ios_rounded,
                            size: 12, color: Colors.white),
                        SizedBox(width: 6),
                        Text('Previous',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: _goNext,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.lime500,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Get Started',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 12, color: Colors.white),
                      ],
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
