import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/remembered_login_storage.dart';
import '../providers/auth_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_background.dart';
import 'otp_verify_screen.dart';

class OtpRequestScreen extends ConsumerStatefulWidget {
  // Set when the user landed here because their session expired mid-use
  // (api_client.dart's refresh failed) rather than by opening the app logged
  // out — they need to be told why they're suddenly back at login.
  final bool sessionExpired;
  const OtpRequestScreen({super.key, this.sessionExpired = false});

  @override
  ConsumerState<OtpRequestScreen> createState() => _OtpRequestScreenState();
}

class _OtpRequestScreenState extends ConsumerState<OtpRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isFocused = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
    _loadRememberedMobile();
    if (widget.sessionExpired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Your session expired. Please sign in again.')),
        );
      });
    }
  }

  // Last "Remember me" login: pre-fill its number with the box ticked.
  Future<void> _loadRememberedMobile() async {
    final mobile = await RememberedLoginStorage.readMobile();
    if (!mounted || mobile == null || _mobileController.text.isNotEmpty) {
      return;
    }
    setState(() {
      _mobileController.text = mobile;
      _rememberMe = true;
    });
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      if (previous?.step != AuthStep.otpSent && next.step == AuthStep.otpSent) {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const OtpVerifyScreen()));
      }
    });

    return AuthBackground(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Welcome Heading ---
            const Text(
              'Welcome Back!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Login to continue and book your services',
              style: TextStyle(
                color: AppColors.slate400,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

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
                            spreadRadius: 1)
                      ]
                    : [],
              ),
              child: TextFormField(
                controller: _mobileController,
                focusNode: _focusNode,
                style: const TextStyle(
                    color: Colors.white, fontSize: 16, letterSpacing: 1.0),
                keyboardType: TextInputType.phone,
                maxLength: 10,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: authFieldDecoration(
                  label: 'Enter mobile number',
                  icon: Icons.phone_outlined,
                  prefixText: '+91  ',
                ).copyWith(counterText: ''),
                validator: (value) =>
                    (value == null || value.trim().length < 10)
                        ? 'Enter valid 10-digit number'
                        : null,
              ),
            ),
            const SizedBox(height: 16),

            // --- Remember Me ---
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _rememberMe
                              ? AppColors.lime500
                              : AppColors.slate400,
                          width: 1.5),
                      color:
                          _rememberMe ? Colors.transparent : Colors.transparent,
                    ),
                    child: _rememberMe
                        ? const Icon(Icons.check,
                            size: 14, color: AppColors.lime500)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Remember me',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 24),

            // --- Error banner ---
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: authState.errorMessage != null
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.red400.withValues(alpha: 0.1),
                          border: Border.all(
                              color: AppColors.red400.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppColors.red400, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(authState.errorMessage!,
                                    style: const TextStyle(
                                        color: AppColors.red400,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500))),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // --- Submit button ---
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.lime500,
                  foregroundColor: AppColors.slate950,
                  disabledBackgroundColor:
                      AppColors.lime500.withValues(alpha: 0.3),
                  disabledForegroundColor:
                      AppColors.slate950.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: authState.isLoading ? null : _submit,
                child: authState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: AppColors.slate950))
                    : const Text('Login',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),

            // --- Secure Login Footer ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined,
                    color: AppColors.lime500.withValues(alpha: 0.8), size: 18),
                const SizedBox(width: 8),
                // Flexible so the line wraps rather than overflowing once the
                // device's text-scale setting is turned up — at large scales
                // this string is wider than a narrow phone's card.
                Flexible(
                  child: Text(
                    'Secure Login. Your data is safe with us.',
                    style: TextStyle(
                        color: AppColors.slate400.withValues(alpha: 0.8),
                        fontSize: 12),
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
      ref
          .read(authProvider.notifier)
          .requestOtp(_mobileController.text.trim(), rememberMe: _rememberMe);
    }
  }
}
