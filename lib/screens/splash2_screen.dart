import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'splash3_screen.dart';

class Splash2Screen extends StatefulWidget {
  final Widget nextScreen;
  const Splash2Screen({super.key, required this.nextScreen});

  @override
  State<Splash2Screen> createState() => _Splash2ScreenState();
}

class _Splash2ScreenState extends State<Splash2Screen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(minutes: 10), _goNext);
  }

  void _goNext() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => widget.nextScreen),
      (route) => false,
    );
  }

  // Pushed (not replaced) so Splash3Screen's Previous button has this route
  // to pop back to.
  void _goNextStep() {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => Splash3Screen(nextScreen: widget.nextScreen)),
    );
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
                  // Logo
                  const SizedBox(height: 56),
                  Image.asset(
                    'assets/images/logo.png',
                    height: 48,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  // Titles
                  const Text('All Services',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  const Text('At Your Fingertips',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.lime500)),
                ],
              ),
            ),
            // Center Image — transparent-background PNG, so it sits directly
            // on the black scaffold. Given only a slim horizontal inset
            // (unlike the 24px around the rest of the page) so it renders
            // bigger.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                // Scaled down a little so the illustration doesn't crowd the
                // heading and buttons.
                child: Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.92,
                    heightFactor: 0.92,
                    child: Image.asset(
                      'assets/login/citycalls_service_mascot_infographic.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                'Book trusted professionals for AC repair,\ncleaning, pest control, beauty services\nand more.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.45,
                  color: AppColors.slate400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _goNextStep,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.lime500,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Next',
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
