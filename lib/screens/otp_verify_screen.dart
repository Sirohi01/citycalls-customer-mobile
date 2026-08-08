import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_background.dart';
import 'profile_setup_screen.dart';
import 'main_shell.dart';
import '../providers/customer_providers.dart';

class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({super.key});

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // --- Icon badge ---
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.lime500.withValues(alpha: 0.9),
                        AppColors.lime500.withValues(alpha: 0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.lime500.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.verified_user_rounded, color: AppColors.slate950, size: 28),
                ),
                // --- Back button ---
                InkWell(
                  onTap: () {
                    ref.read(authProvider.notifier).backToMobileEntry();
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Back', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- Heading ---
            const Text(
              'Secure Verification',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Enter the 6-digit authentication code we sent to\n+91 ${authState.mobile ?? ''}',
              style: const TextStyle(
                color: AppColors.slate400,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),

            // --- OTP field ---
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: AppColors.lime500.withValues(alpha: 0.18),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
              child: TextFormField(
                controller: _otpController,
                focusNode: _focusNode,
                autofocus: true,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 10,
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                decoration: authFieldDecoration(
                  label: 'Authentication Code',
                  icon: null,
                ).copyWith(
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                validator: (value) => (value == null || value.length != 6)
                    ? 'Please enter the complete 6-digit code'
                    : null,
              ),
            ),
            const SizedBox(height: 22),

            // --- Error banner ---
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: authState.errorMessage != null
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.red400.withValues(alpha: 0.1),
                          border: Border.all(color: AppColors.red400.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.red400, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                authState.errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.red400,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // --- Verify button ---
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                style: authButtonStyle().copyWith(
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  elevation: const WidgetStatePropertyAll(0),
                ),
                onPressed: authState.isLoading ? null : _submit,
                child: authState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_open_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Verify Identity',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // --- Resend code ---
            Center(
              child: TextButton(
                onPressed: authState.isLoading || authState.mobile == null
                    ? null
                    : () => ref.read(authProvider.notifier).requestOtp(authState.mobile!),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text('Resend Code'),
                  ],
                ),
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
    final authState = ref.read(authProvider);

    // If it's a signup flow with pre-filled name, auto-save profile
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
        // Fallback if update fails
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