import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer_models.dart';
import '../providers/auth_providers.dart';
import '../providers/customer_providers.dart';
import '../providers/realtime_providers.dart';
import '../providers/push_providers.dart';
import '../providers/theme_providers.dart';
import '../theme/app_theme.dart';
import 'otp_request_screen.dart';
import 'saved_products_screen.dart';
import 'notification_preferences_screen.dart';
import 'support_screen.dart';

// Per docs/rohit/05-customer-app-screen-list.md "Profile" — Profile edit,
// Address book, Saved Products, Notification Preferences, plus Help & Support.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider);
    final beautyMode = ref.watch(beautyModeProvider);

    return Scaffold(
      backgroundColor: AppColors.neutral100,
      appBar: AppBar(title: const Text('Profile'), centerTitle: false, backgroundColor: AppColors.neutral100, surfaceTintColor: AppColors.neutral100),
      body: profile.when(
        data: (customer) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2)),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                child: Text(
                  customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(customer.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            if (customer.mobile != null) Text('+91 ${customer.mobile}', style: const TextStyle(color: AppColors.neutral500)),
            if (customer.email != null) Text(customer.email!, style: const TextStyle(color: AppColors.neutral500)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _showEditProfileSheet(context, ref, customer),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit Profile'),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Saved Addresses', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => _showAddressSheet(context, ref, customer.id),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (customer.addresses.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
                child: const Text('No saved addresses yet.', style: TextStyle(color: AppColors.neutral500)),
              )
            else
              ...customer.addresses.map(
                (a) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.location_on_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          [a.label, a.line1, a.city, a.state, a.pinCode].where((s) => s != null && s.isNotEmpty).join(', '),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18, color: AppColors.neutral500),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showAddressSheet(context, ref, customer.id, existing: a);
                          } else if (value == 'delete') {
                            _confirmDeleteAddress(context, ref, customer.id, a.id);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 28),
            const Text('More', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.beautyAccent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.beautyPrimary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.spa_outlined, color: AppColors.beautyPrimary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Beauty Mode', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.beautyAccentForeground)),
                        Text('Switch the app to our Bliss & Salon look', style: TextStyle(color: AppColors.beautyAccentForeground, fontSize: 11.5)),
                      ],
                    ),
                  ),
                  Switch(
                    value: beautyMode,
                    activeColor: AppColors.beautyPrimary,
                    onChanged: (_) => ref.read(beautyModeProvider.notifier).toggle(),
                  ),
                ],
              ),
            ),
            _MenuTile(
              icon: Icons.build_outlined,
              label: 'Saved Appliances',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SavedProductsScreen())),
            ),
            _MenuTile(
              icon: Icons.notifications_outlined,
              label: 'Notification Preferences',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationPreferencesScreen())),
            ),
            _MenuTile(
              icon: Icons.help_outline,
              label: 'Help & Support',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportScreen())),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _logout(context, ref),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load profile: $err')),
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context, WidgetRef ref, Customer customer) {
    final nameController = TextEditingController(text: customer.name);
    final emailController = TextEditingController(text: customer.email ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full name')),
            const SizedBox(height: 12),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email (optional)')),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
              onPressed: () async {
                await ref.read(customerRepositoryProvider).updateProfile(
                      customer.id,
                      name: nameController.text.trim(),
                      email: emailController.text.trim(),
                    );
                ref.invalidate(myProfileProvider);
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddressSheet(BuildContext context, WidgetRef ref, String customerId, {CustomerAddress? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _AddressFormSheet(
        customerId: customerId,
        existing: existing,
        onSaved: () {
          Navigator.of(sheetContext).pop();
          ref.invalidate(myProfileProvider);
        },
      ),
    );
  }

  void _confirmDeleteAddress(BuildContext context, WidgetRef ref, String customerId, String addressId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref.read(customerRepositoryProvider).deleteAddress(customerId, addressId);
              ref.invalidate(myProfileProvider);
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    // Must run before authRepository.logout() clears the stored access
    // token — unregisterCurrentToken's DELETE call needs it to identify
    // "me" server-side.
    await ref.read(pushNotificationServiceProvider).unregisterCurrentToken();
    await ref.read(authRepositoryProvider).logout();
    // Without this, the socket stays connected under the outgoing account's
    // JWT for the rest of this app process's lifetime — SocketService is a
    // long-lived singleton Provider, not scoped to a login session.
    ref.read(socketServiceProvider).disconnect();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OtpRequestScreen()),
      (route) => false,
    );
  }
}

class _AddressFormSheet extends ConsumerStatefulWidget {
  final String customerId;
  final CustomerAddress? existing;
  final VoidCallback onSaved;
  const _AddressFormSheet({required this.customerId, this.existing, required this.onSaved});

  @override
  ConsumerState<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends ConsumerState<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _labelController = TextEditingController(text: widget.existing?.label);
  late final _line1Controller = TextEditingController(text: widget.existing?.line1);
  late final _line2Controller = TextEditingController(text: widget.existing?.line2);
  late final _landmarkController = TextEditingController(text: widget.existing?.landmark);
  late final _cityController = TextEditingController(text: widget.existing?.city);
  late final _stateController = TextEditingController(text: widget.existing?.state);
  late final _pinCodeController = TextEditingController(text: widget.existing?.pinCode);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _labelController.dispose();
    _line1Controller.dispose();
    _line2Controller.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(customerRepositoryProvider);
      if (widget.existing != null) {
        await repo.updateAddress(
          widget.customerId,
          widget.existing!.id,
          label: _labelController.text.trim(),
          line1: _line1Controller.text.trim(),
          line2: _line2Controller.text.trim(),
          landmark: _landmarkController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          pinCode: _pinCodeController.text.trim(),
        );
      } else {
        await repo.addAddress(
          widget.customerId,
          label: _labelController.text.trim(),
          line1: _line1Controller.text.trim(),
          line2: _line2Controller.text.trim(),
          landmark: _landmarkController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          pinCode: _pinCodeController.text.trim(),
        );
      }
      widget.onSaved();
    } catch (e) {
      setState(() => _error = 'Failed to save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.existing != null ? 'Edit Address' : 'Add Address', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(controller: _labelController, decoration: const InputDecoration(labelText: 'Label (e.g. Home, Office)')),
              const SizedBox(height: 10),
              TextFormField(
                controller: _line1Controller,
                decoration: const InputDecoration(labelText: 'House / Flat / Street'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(controller: _line2Controller, decoration: const InputDecoration(labelText: 'Area (optional)')),
              const SizedBox(height: 10),
              TextFormField(controller: _landmarkController, decoration: const InputDecoration(labelText: 'Landmark (optional)')),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'City'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(labelText: 'State'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _pinCodeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'PIN Code'),
                validator: (v) => (v == null || v.trim().length < 4) ? 'Enter a valid PIN code' : null,
              ),
              if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: Colors.red))),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                onPressed: _saving ? null : _save,
                child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.03),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.neutral100, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: AppColors.neutral500, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
              const Icon(Icons.chevron_right, color: AppColors.neutral200),
            ],
          ),
        ),
      ),
    );
  }
}
