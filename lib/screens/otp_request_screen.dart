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
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isFocused = false;
  bool _isLogin = true;
  bool _termsConsent = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _focusNode.dispose();
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
            // --- Logo / icon badge & Heading ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
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
                  child: const Icon(Icons.lock_person_rounded, color: AppColors.slate950, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _isLogin ? 'Welcome Back' : 'Create Account',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _isLogin 
                  ? 'Enter your mobile number to securely sign in to your account.'
                  : 'Join us today. Enter your mobile number to get started.',
              style: const TextStyle(
                color: AppColors.slate400,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),

            // --- Full Name Field (Sign Up Only) ---
            if (!_isLogin) ...[
              TextFormField(
                controller: _nameController,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
                decoration: authFieldDecoration(
                  label: 'Full Name',
                  icon: Icons.person_outline_rounded,
                ),
                validator: (value) => (value == null || value.trim().length < 2)
                    ? 'Please enter your full name'
                    : null,
              ),
              const SizedBox(height: 22),
            ],

            // --- Mobile number field ---
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
                controller: _mobileController,
                focusNode: _focusNode,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
                keyboardType: TextInputType.phone,
                maxLength: 10,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: authFieldDecoration(
                  label: 'Mobile Number',
                  icon: Icons.phone_android_rounded,
                  prefixText: '+91  ',
                ).copyWith(counterText: ''),
                validator: (value) => (value == null || value.trim().length < 10)
                    ? 'Please enter a valid 10-digit mobile number'
                    : null,
              ),
            ),
            const SizedBox(height: 22),

            // --- Email Field (Sign Up Only) ---
            if (!_isLogin) ...[
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
                decoration: authFieldDecoration(
                  label: 'Email Address (Optional)',
                  icon: Icons.mail_outline_rounded,
                ),
              ),
              const SizedBox(height: 22),
              
              // --- Terms Consent ---
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _termsConsent,
                      onChanged: (val) => setState(() => _termsConsent = val ?? false),
                      activeColor: AppColors.lime500,
                      checkColor: AppColors.slate950,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'I agree to the Terms & Conditions',
                      style: TextStyle(color: AppColors.slate300, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
            ],

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

            // --- Submit button ---
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
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isLogin ? 'Continue' : 'Sign Up',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2),
                          ),
                          const SizedBox(width: 8),
                          if (_isLogin) const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 28),

            
            // --- Toggle link ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isLogin ? "Don't have an account? " : "Already have an account? ",
                  style: const TextStyle(color: AppColors.slate400, fontSize: 14),
                ),
                GestureDetector(
                  onTap: () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin ? "Sign up" : "Sign in",
                    style: const TextStyle(
                      color: AppColors.lime400,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.lime400,
                    ),
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
    if (!_isLogin && !_termsConsent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please agree to the Terms & Conditions'),
          backgroundColor: AppColors.red500,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authProvider.notifier).requestOtp(
        _mobileController.text.trim(),
        signupName: _isLogin ? null : _nameController.text.trim(),
        signupEmail: _isLogin ? null : _emailController.text.trim(),
      );
    }
  }
}