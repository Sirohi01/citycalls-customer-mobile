import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/customer_providers.dart';
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const Text('Tell us about you', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Just a couple of details before you start booking services.', style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (value) => (value == null || value.trim().length < 2) ? 'Enter your name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email (optional)'),
                ),
                const SizedBox(height: 20),
                // Consent must be captured explicitly, never pre-checked —
                // docs/17-security-and-audit.md §8.
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _whatsappConsent,
                  onChanged: (v) => setState(() => _whatsappConsent = v ?? false),
                  title: const Text('Send me booking updates on WhatsApp'),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _emailConsent,
                  onChanged: (v) => setState(() => _emailConsent = v ?? false),
                  title: const Text('Send me updates by email'),
                ),
                const SizedBox(height: 12),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text('$error', style: const TextStyle(color: Colors.red)),
                  ),
                FilledButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Continue'),
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
