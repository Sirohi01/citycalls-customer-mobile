import 'package:flutter/material.dart';
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
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => widget.nextScreen),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            children: [
              // Logo
              const SizedBox(height: 16),
              Image.asset(
                'assets/images/logocalls.png',
                height: 48, 
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              // Titles
              const Text('Quick Booking,', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.black, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              const Text('Easy & Fast', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.lime500)),
              const SizedBox(height: 16),
              // Center Image
              Expanded(
                child: Transform.scale(
                  scale: 1.1,
                  child: Image.asset(
                    'assets/login/splace4.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Description
              const Text(
                'Book in just a few taps and relax,\nwe\'ll take care of the rest.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.neutral500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 48),
              // Bottom Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _goNext,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Skip', style: TextStyle(color: AppColors.black, fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  // Dots
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.neutral200, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.neutral200, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.neutral200, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.lime500, shape: BoxShape.circle)),
                    ],
                  ),
                  FilledButton(
                    onPressed: _goNext,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.lime500,
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Get Started', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
