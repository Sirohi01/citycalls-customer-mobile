import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import '../providers/customer_providers.dart';
import '../theme/app_theme.dart';

// Per docs/rohit/05-customer-app-screen-list.md "Profile" — Notification
// Preferences / Consent management. Backed by the existing
// PATCH /customers/:id/consent (docs/17-security-and-audit.md §8 — every
// change is audit-logged server-side, not just a client-side toggle).
class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.neutral100,
      appBar: AppBar(title: const Text('Notification Preferences'), centerTitle: false, backgroundColor: AppColors.neutral100, surfaceTintColor: AppColors.neutral100),
      body: profile.when(
        data: (customer) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Choose how CityCalls can reach you with booking updates and offers.',
              style: TextStyle(color: AppColors.neutral500),
            ),
            const SizedBox(height: 20),
            _ConsentTile(
              icon: Icons.chat_outlined,
              label: 'WhatsApp',
              channel: 'whatsapp',
              granted: customer.consent['whatsapp'] == 'GRANTED',
              customerId: customer.id,
            ),
            _ConsentTile(
              icon: Icons.mail_outline,
              label: 'Email',
              channel: 'email',
              granted: customer.consent['email'] == 'GRANTED',
              customerId: customer.id,
            ),
            _ConsentTile(
              icon: Icons.sms_outlined,
              label: 'SMS',
              channel: 'sms',
              granted: customer.consent['sms'] == 'GRANTED',
              customerId: customer.id,
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load preferences: $err')),
      ),
    );
  }
}

class _ConsentTile extends ConsumerStatefulWidget {
  final IconData icon;
  final String label;
  final String channel;
  final bool granted;
  final String customerId;
  const _ConsentTile({required this.icon, required this.label, required this.channel, required this.granted, required this.customerId});

  @override
  ConsumerState<_ConsentTile> createState() => _ConsentTileState();
}

class _ConsentTileState extends ConsumerState<_ConsentTile> {
  bool _saving = false;

  Future<void> _toggle(bool value) async {
    setState(() => _saving = true);
    try {
      await ref.read(customerRepositoryProvider).updateConsent(widget.customerId, widget.channel, value ? 'GRANTED' : 'REVOKED');
      ref.invalidate(myProfileProvider);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: widget.granted ? primary.withValues(alpha: 0.1) : AppColors.neutral100, borderRadius: BorderRadius.circular(10)),
            child: Icon(widget.icon, color: widget.granted ? primary : AppColors.neutral500, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600))),
          if (_saving)
            const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
          else
            Switch(value: widget.granted, onChanged: _toggle, activeColor: primary),
        ],
      ),
    );
  }
}
