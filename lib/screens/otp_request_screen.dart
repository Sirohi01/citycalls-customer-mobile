import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_background.dart';
import 'otp_verify_screen.dart';

class OtpRequestScreen extends ConsumerStatefulWidget {
  const OtpRequestScreen({super.key});

  @override
  ConsumerState<OtpRequestScreen> createState() => _OtpRequestScreenState();
}

class _OtpRequestScreenState extends ConsumerState<OtpRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      if (previous?.step != AuthStep.otpSent && next.step == AuthStep.otpSent) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OtpVerifyScreen()));
      }
    });

    return AuthBackground(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Welcome Back',
              style: TextStyle(
                  color: Colors.white, 
                  fontSize: 28, 
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your mobile number to securely sign in or create a new account.',
              style: TextStyle(
                  color: AppColors.slate300.withValues(alpha: 0.9), 
                  fontSize: 15,
                  height: 1.5),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _mobileController,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 1),
              keyboardType: TextInputType.phone,
              maxLength: 10,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: authFieldDecoration(
                label: 'Mobile Number', 
                icon: Icons.phone_android_rounded, 
                prefixText: '+91  '
              ).copyWith(counterText: ''),
              validator: (value) => (value == null || value.trim().length < 10) 
                  ? 'Please enter a valid 10-digit mobile number' 
                  : null,
            ),
            const SizedBox(height: 24),
            if (authState.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.red400.withValues(alpha: 0.1),
                    border: Border.all(color: AppColors.red400.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.red400, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(authState.errorMessage!, style: const TextStyle(color: AppColors.red400, fontSize: 13, fontWeight: FontWeight.w500))),
                    ],
                  ),
                ),
              ),
            FilledButton(
              style: authButtonStyle(),
              onPressed: authState.isLoading ? null : _submit,
              child: authState.isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.slate950))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Continue'), 
                        SizedBox(width: 8), 
                        Icon(Icons.arrow_forward_rounded, size: 20)
                      ],
                    ),
            ),
            const SizedBox(height: 28),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_rounded, color: AppColors.lime500.withValues(alpha: 0.8), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your data is secured with enterprise-grade encryption. We never share your details.',
                    style: TextStyle(color: AppColors.slate400.withValues(alpha: 0.8), fontSize: 12, height: 1.5, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authProvider.notifier).requestOtp(_mobileController.text.trim());
    }
  }
}
