import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/customer_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_background.dart';
import 'main_shell.dart';

// Per docs/rohit/05-customer-app-screen-list.md "Onboarding" — Registration/
// Profile Setup, shown once after a customer's very first OTP login (their
// Customer record still has the 'Customer' placeholder name from
// auth.service.ts's progressive registration).
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _whatsappConsent = false;
  bool _emailConsent = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saveState = ref.watch(profileSetupProvider);
    final isLoading = saveState?.isLoading ?? false;
    final error = saveState?.hasError ?? false ? saveState!.error : null;

    ref.listen(profileSetupProvider, (previous, next) {
      if (next != null && next.hasValue && !next.isLoading) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
      }
    });

    return AuthBackground(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
              child: const Icon(Icons.person_add_rounded, color: AppColors.slate950, size: 28),
            ),
            const SizedBox(height: 24),
            
            // --- Heading ---
            const Text(
              'Tell us about you', 
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                height: 1.1,
              )
            ),
            const SizedBox(height: 10),
            const Text(
              'Just a couple of details before you start booking services.', 
              style: TextStyle(
                color: AppColors.slate400,
                fontSize: 15,
                height: 1.5,
              )
            ),
            const SizedBox(height: 36),
            
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
              decoration: authFieldDecoration(
                label: 'Full name', 
                icon: Icons.person_outline_rounded
              ),
              validator: (value) => (value == null || value.trim().length < 2) ? 'Enter your name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
              decoration: authFieldDecoration(
                label: 'Email (optional)', 
                icon: Icons.mail_outline_rounded
              ),
            ),
            const SizedBox(height: 24),
                // Consent must be captured explicitly, never pre-checked
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2), 
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        value: _whatsappConsent,
                        onChanged: (v) => setState(() => _whatsappConsent = v ?? false),
                        title: const Text('Send me booking updates on WhatsApp', style: TextStyle(fontSize: 13.5, color: AppColors.slate300)),
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        activeColor: AppColors.lime400,
                        checkColor: AppColors.slate950,
                      ),
                      CheckboxListTile(
                        value: _emailConsent,
                        onChanged: (v) => setState(() => _emailConsent = v ?? false),
                        title: const Text('Send me updates by email', style: TextStyle(fontSize: 13.5, color: AppColors.slate300)),
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        activeColor: AppColors.lime400,
                        checkColor: AppColors.slate950,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (error != null)
                  Padding(
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
                          const Icon(Icons.error_outline_rounded, color: AppColors.red500, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '$error',
                              style: const TextStyle(
                                color: AppColors.red500,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Complete Profile',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20),
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
      ref.read(profileSetupProvider.notifier).save(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            whatsappConsent: _whatsappConsent,
            emailConsent: _emailConsent,
          );
    }
  }
}
