import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class AuthBackground extends StatefulWidget {
  final Widget child;
  const AuthBackground({super.key, required this.child});

  @override
  State<AuthBackground> createState() => _AuthBackgroundState();
}

class _AuthBackgroundState extends State<AuthBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _bgController;
  late Animation<double> _fadeLogo;
  late Animation<Offset> _slideLogo;
  late Animation<double> _fadeCard;
  late Animation<Offset> _slideCard;

  @override
  void initState() {
    super.initState();
    // Ensure status bar is light for dark theme
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _bgController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat(reverse: true);

    _fadeLogo = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _slideLogo =
        Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic)),
    );

    _fadeCard = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
    );
    _slideCard =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sleek Logo Presentation
                FadeTransition(
                  opacity: _fadeLogo,
                  child: SlideTransition(
                    position: _slideLogo,
                    child: Image.asset('assets/images/logo.png',
                        height: 72, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 36),
                FadeTransition(
                  opacity: _fadeCard,
                  child: SlideTransition(
                    position: _slideCard,
                    child: _AuthCard(child: widget.child),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  final Widget child;
  const _AuthCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.slate900,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 15),
          )
        ],
      ),
      child: child,
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
    labelStyle: TextStyle(
        color: AppColors.slate300.withValues(alpha: 0.8), fontSize: 14),
    prefixIcon: icon != null
        ? Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(icon, color: AppColors.slate400, size: 22),
          )
        : null,
    prefixText: prefixText,
    prefixStyle: const TextStyle(
        color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
    errorText: errorText,
    errorStyle:
        const TextStyle(color: AppColors.red400, fontWeight: FontWeight.w500),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.05),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide:
          BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide:
          BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
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
    textStyle: const TextStyle(
        fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );
}
