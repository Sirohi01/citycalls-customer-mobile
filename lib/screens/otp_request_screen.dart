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
  // Ticked by default: logging in keeps you logged in until you log out.
  bool _rememberMe = true;
  // Number of the last login on this phone, offered as a one-tap option.
  String? _savedMobile;
  // True once the user picks "Use a different number".
  bool _useDifferentNumber = false;

  bool get _showSavedNumber => _savedMobile != null && !_useDifferentNumber;

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

  Future<void> _loadRememberedMobile() async {
    final mobile = await RememberedLoginStorage.readMobile();
    if (!mounted || mobile == null || mobile.length != 10) return;
    // Don't swap the field away if they already started typing.
    if (_mobileController.text.isNotEmpty) return;
    setState(() => _savedMobile = mobile);
  }

  static String _pretty(String m) =>
      '+91 ${m.substring(0, 5)} ${m.substring(5)}';

  // "Continue with +91 …" card shown instead of the field.
  Widget _savedNumberCard(String mobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.lime500.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.lime500.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.phone_iphone_rounded,
                color: AppColors.lime400),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Continue with',
                    style:
                        TextStyle(color: AppColors.slate400, fontSize: 12.5)),
                const SizedBox(height: 3),
                Text(_pretty(mobile),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppColors.lime500),
        ],
      ),
    );
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

            // --- Last-used number, or the mobile number field ---
            if (_showSavedNumber) ...[
              _savedNumberCard(_savedMobile!),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: authState.isLoading
                      ? null
                      : () {
                          setState(() => _useDifferentNumber = true);
                          ref.read(authProvider.notifier).backToMobileEntry();
                          WidgetsBinding.instance.addPostFrameCallback(
                              (_) => _focusNode.requestFocus());
                        },
                  style:
                      TextButton.styleFrom(foregroundColor: AppColors.lime400),
                  child: const Text('Use a different number',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ] else ...[
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
              if (_savedMobile != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: authState.isLoading
                        ? null
                        : () => setState(() {
                              _useDifferentNumber = false;
                              _mobileController.clear();
                            }),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.lime400),
                    child: Text('Use ${_pretty(_savedMobile!)} instead',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
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
    if (_showSavedNumber) {
      ref
          .read(authProvider.notifier)
          .requestOtp(_savedMobile!, rememberMe: _rememberMe);
      return;
    }
    if (_formKey.currentState?.validate() ?? false) {
      ref
          .read(authProvider.notifier)
          .requestOtp(_mobileController.text.trim(), rememberMe: _rememberMe);
    }
  }
}
