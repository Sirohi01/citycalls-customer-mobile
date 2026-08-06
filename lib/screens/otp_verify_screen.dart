import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_background.dart';
import 'profile_setup_screen.dart';
import 'main_shell.dart';

class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({super.key});

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      if (previous?.step != AuthStep.loggedIn && next.step == AuthStep.loggedIn) {
        _routeAfterLogin(context, ref);
      }
    });

    return AuthBackground(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                ref.read(authProvider.notifier).backToMobileEntry();
                Navigator.of(context).pop();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1))
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_rounded, color: AppColors.slate300, size: 18),
                    SizedBox(width: 8),
                    Text('Back', style: TextStyle(color: AppColors.slate300, fontWeight: FontWeight.w500, fontSize: 13)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Secure Verification',
              style: TextStyle(
                  color: Colors.white, 
                  fontSize: 28, 
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the 6-digit authentication code we sent to\n+91 ${authState.mobile ?? ''}',
              style: TextStyle(
                  color: AppColors.slate300.withValues(alpha: 0.9), 
                  fontSize: 15,
                  height: 1.5),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _otpController,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 8),
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              decoration: authFieldDecoration(
                label: 'Authentication Code', 
                icon: null,
              ).copyWith(
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(vertical: 20),
              ),
              validator: (value) => (value == null || value.length != 6) 
                  ? 'Please enter the complete 6-digit code' 
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
                  : const Text('Verify Identity'),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: authState.isLoading || authState.mobile == null
                    ? null
                    : () => ref.read(authProvider.notifier).requestOtp(authState.mobile!),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.lime400,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                child: const Text('Resend Code'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authProvider.notifier).verifyOtp(_otpController.text.trim());
    }
  }

  Future<void> _routeAfterLogin(BuildContext context, WidgetRef ref) async {
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
