import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import '../theme/app_theme.dart';
import 'profile_setup_screen.dart';
import 'main_shell.dart';
import '../providers/customer_providers.dart';

class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({super.key});

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  String _otpCode = "";
  Timer? _timer;
  int _secondsLeft = 25;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _secondsLeft = 25;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        timer.cancel();
      }
    });
  }

  void _onKeypadTap(String value) {
    if (value == 'clear') {
      if (_otpCode.isNotEmpty) {
        setState(() => _otpCode = _otpCode.substring(0, _otpCode.length - 1));
      }
    } else {
      if (_otpCode.length < 6) {
        setState(() => _otpCode += value);
        if (_otpCode.length == 6) {
          _submit();
        }
      }
    }
  }

  void _submit() {
    ref.read(authProvider.notifier).verifyOtp(_otpCode);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      if (previous?.step != AuthStep.loggedIn && next.step == AuthStep.loggedIn) {
        _routeAfterLogin(context, ref);
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // --- Header (Back Button & Logo) ---
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    ref.read(authProvider.notifier).backToMobileEntry();
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
            
            // --- Logo ---
            Center(
              child: Image.asset('assets/images/logo.png', height: 48, fit: BoxFit.contain),
            ),
            const SizedBox(height: 32),

            // --- Texts ---
            const Text(
              'Verify Your Number',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text(
              'Enter the 6 digit code sent to',
              style: TextStyle(color: AppColors.slate400, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              '+91 ${authState.mobile ?? ''}',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 32),

            // --- OTP Squares ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                final hasDigit = index < _otpCode.length;
                return Container(
                  width: 48,
                  height: 56,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasDigit ? AppColors.slate600 : Colors.transparent,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    hasDigit ? _otpCode[index] : '',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // --- Resend Timer ---
            if (authState.isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: AppColors.lime500),
              )
            else if (_secondsLeft > 0)
              Text(
                'Resend code in 00:${_secondsLeft.toString().padLeft(2, '0')}',
                style: const TextStyle(color: AppColors.slate400, fontSize: 14),
              )
            else
              GestureDetector(
                onTap: () {
                  ref.read(authProvider.notifier).requestOtp(authState.mobile!);
                  _startTimer();
                },
                child: const Text(
                  'Resend code',
                  style: TextStyle(color: AppColors.lime500, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),

            // --- Error banner ---
            if (authState.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  authState.errorMessage!,
                  style: const TextStyle(color: AppColors.red400, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),

            const Spacer(),

            // --- Custom Numpad ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Column(
                children: [
                  _NumpadRow(['1', '2', '3'], _onKeypadTap),
                  const SizedBox(height: 12),
                  _NumpadRow(['4', '5', '6'], _onKeypadTap),
                  const SizedBox(height: 12),
                  _NumpadRow(['7', '8', '9'], _onKeypadTap),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 80), // Empty space for left
                      _NumpadButton(label: '0', onTap: _onKeypadTap),
                      _NumpadButton(label: 'clear', icon: Icons.backspace_outlined, onTap: _onKeypadTap),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _routeAfterLogin(BuildContext context, WidgetRef ref) async {
    final authState = ref.read(authProvider);

    if (authState.signupName != null) {
      try {
        await ref.read(profileSetupProvider.notifier).save(
          name: authState.signupName!,
          email: authState.signupEmail ?? '',
          whatsappConsent: false,
          emailConsent: false,
        );
        if (!context.mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
        return;
      } catch (e) {
        // Fallback
      }
    }

    final needsSetup = await ref.read(customerRepositoryProvider).getMyProfile().then(
          (customer) => customer.needsProfileSetup,
          onError: (_) => false,
        );
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => needsSetup ? const ProfileSetupScreen() : const MainShell()),
      (route) => false,
    );
  }
}

class _NumpadRow extends StatelessWidget {
  final List<String> values;
  final Function(String) onTap;

  const _NumpadRow(this.values, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: values.map((val) => _NumpadButton(label: val, onTap: onTap)).toList(),
    );
  }
}

class _NumpadButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Function(String) onTap;

  const _NumpadButton({required this.label, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(label),
      child: Container(
        width: 90,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E20),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: icon != null
            ? Icon(icon, color: Colors.white, size: 24)
            : Text(label, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w500)),
      ),
    );
  }
}