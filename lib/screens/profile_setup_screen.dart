import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/customer_providers.dart';
import '../theme/app_theme.dart';
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

    return Scaffold(
      backgroundColor: AppColors.neutral100,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Icons.waving_hand_rounded, color: Theme.of(context).colorScheme.primary, size: 32),
                ),
                const SizedBox(height: 20),
                const Text('Tell us about you', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Just a couple of details before you start booking services.', style: TextStyle(color: AppColors.neutral500)),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)),
                  validator: (value) => (value == null || value.trim().length < 2) ? 'Enter your name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email (optional)', prefixIcon: Icon(Icons.mail_outline)),
                ),
                const SizedBox(height: 20),
                // Consent must be captured explicitly, never pre-checked —
                // docs/17-security-and-audit.md §8.
                Container(
                  decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        value: _whatsappConsent,
                        onChanged: (v) => setState(() => _whatsappConsent = v ?? false),
                        title: const Text('Send me booking updates on WhatsApp', style: TextStyle(fontSize: 13.5)),
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                      ),
                      CheckboxListTile(
                        value: _emailConsent,
                        onChanged: (v) => setState(() => _emailConsent = v ?? false),
                        title: const Text('Send me updates by email', style: TextStyle(fontSize: 13.5)),
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text('$error', style: const TextStyle(color: Colors.red)),
                  ),
                FilledButton.icon(
                  onPressed: isLoading ? null : _submit,
                  icon: isLoading
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.arrow_forward, size: 18),
                  label: Text(isLoading ? 'Saving...' : 'Continue'),
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
      ref.read(profileSetupProvider.notifier).save(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            whatsappConsent: _whatsappConsent,
            emailConsent: _emailConsent,
          );
    }
  }
}
