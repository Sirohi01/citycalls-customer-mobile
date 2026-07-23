import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import 'profile_setup_screen.dart';
import 'home_screen.dart';

// Per docs/rohit/05-customer-app-screen-list.md "Onboarding" — OTP Verify step.
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
        final needsSetup = next.user?.name == 'Customer';
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => needsSetup ? const ProfileSetupScreen() : const HomeScreen()),
          (route) => false,
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(authProvider.notifier).backToMobileEntry();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Verify OTP', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Enter the 6-digit code sent to +91 ${authState.mobile ?? ''}', style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(labelText: '6-digit OTP', counterText: ''),
                  validator: (value) => (value == null || value.length != 6) ? 'Enter the 6-digit OTP' : null,
                ),
                const SizedBox(height: 12),
                if (authState.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(authState.errorMessage!, style: const TextStyle(color: Colors.red)),
                  ),
                FilledButton(
                  onPressed: authState.isLoading ? null : _submit,
                  child: authState.isLoading
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Verify'),
                ),
                TextButton(
                  onPressed: authState.isLoading || authState.mobile == null
                      ? null
                      : () => ref.read(authProvider.notifier).requestOtp(authState.mobile!),
                  child: const Text('Resend OTP'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authProvider.notifier).verifyOtp(_otpController.text.trim());
    }
  }
}
