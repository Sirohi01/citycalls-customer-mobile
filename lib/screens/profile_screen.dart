import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer_models.dart';
import '../providers/auth_providers.dart';
import '../providers/customer_providers.dart';
import '../providers/realtime_providers.dart';
import '../providers/push_providers.dart';
import '../providers/theme_providers.dart';
import 'otp_request_screen.dart';
import 'saved_products_screen.dart';
import 'notification_preferences_screen.dart';
import 'support_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider);
    final beautyMode = ref.watch(beautyModeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          // Background Gradient (Top)
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [const Color(0xFF16A34A).withValues(alpha: 0.1), Colors.transparent],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Custom Header (Back Button & Title) ---
                Padding(
                  padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back, color: Color(0xFF16A34A), size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text('Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87)),
                    ],
                  ),
                ),
                
                Expanded(
                  child: profile.when(
                    data: (customer) => ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      children: [
                        // --- Profile Info Card ---
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              SizedBox(
                                width: 64,
                                height: 64,
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: const BoxDecoration(color: Color(0xFF0F5132), shape: BoxShape.circle),
                                      alignment: Alignment.center,
                                      child: Text(
                                        customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE6F4EA),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                        child: const Icon(Icons.camera_alt_outlined, size: 12, color: Color(0xFF0F5132)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(customer.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                                    const SizedBox(height: 4),
                                    if (customer.mobile != null)
                                      Row(
                                        children: [
                                          const Icon(Icons.phone_outlined, size: 12, color: Colors.black54),
                                          const SizedBox(width: 4),
                                          Text('+91 ${customer.mobile}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                                        ],
                                      ),
                                    const SizedBox(height: 2),
                                    if (customer.email != null)
                                      Row(
                                        children: [
                                          const Icon(Icons.email_outlined, size: 12, color: Colors.black54),
                                          const SizedBox(width: 4),
                                          Expanded(child: Text(customer.email!, style: const TextStyle(color: Colors.black54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              // Edit Button
                              InkWell(
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE6F4EA),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.edit_outlined, size: 12, color: Color(0xFF16A34A)),
                                      SizedBox(width: 4),
                                      Text('Edit Profile', style: TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // --- Saved Addresses ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.location_on, color: Color(0xFF0F5132), size: 18),
                                SizedBox(width: 8),
                                Text('Saved Addresses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                              ],
                            ),
                            InkWell(
                              onTap: () => _showAddressSheet(context, ref, customer.id),
                              child: const Row(
                                children: [
                                  Icon(Icons.add, color: Color(0xFF16A34A), size: 14),
                                  SizedBox(width: 2),
                                  Text('Add', style: TextStyle(color: Color(0xFF16A34A), fontSize: 13, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        if (customer.addresses.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                            child: const Text('No saved addresses yet.', style: TextStyle(color: Colors.black54, fontSize: 13)),
                          )
                        else
                          ...customer.addresses.map((a) {
                            // Determine style based on label
                            final labelLower = (a.label ?? '').toLowerCase();
                            IconData iconData = Icons.location_on_outlined;
                            Color badgeBg = const Color(0xFFF3F4F6); // Gray for other
                            Color badgeText = const Color(0xFF4B5563);
                            
                            if (labelLower == 'home') {
                              iconData = Icons.home_outlined;
                              badgeBg = const Color(0xFFE6F4EA);
                              badgeText = const Color(0xFF16A34A);
                            } else if (labelLower == 'office') {
                              iconData = Icons.business_outlined;
                              badgeBg = const Color(0xFFE0E7FF);
                              badgeText = const Color(0xFF4338CA);
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Icon
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0FDF4),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(iconData, size: 20, color: const Color(0xFF16A34A)),
                                  ),
                                  const SizedBox(width: 12),
                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(8)),
                                          child: Text(a.label ?? '', style: TextStyle(color: badgeText, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          [a.line1, a.city, a.state, a.pinCode].where((s) => s != null && s.isNotEmpty).join(', '),
                                          style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.3),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Actions
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, size: 18, color: Colors.black87),
                                        padding: EdgeInsets.zero,
                                        onSelected: (value) {
                                          if (value == 'edit') _showAddressSheet(context, ref, customer.id, existing: a);
                                          else if (value == 'delete') _confirmDeleteAddress(context, ref, customer.id, a.id);
                                        },
                                        itemBuilder: (context) => const [
                                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                                        ],
                                      ),
                                      // If default, show badge (mocking for home)
                                      if (labelLower == 'home')
                                        Container(
                                          margin: const EdgeInsets.only(top: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: const Color(0xFFE6F4EA), borderRadius: BorderRadius.circular(6)),
                                          child: const Text('Default', style: TextStyle(color: Color(0xFF16A34A), fontSize: 9, fontWeight: FontWeight.bold)),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                          
                        const SizedBox(height: 16),
                        
                        // --- More Section ---
                        const Text('More', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 12),
                        
                        // Beauty Mode
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2), // Light pink
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFECDD3).withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_florist_outlined, color: Color(0xFFE11D48), size: 24),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Beauty Mode', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFBE123C), fontSize: 14)),
                                    SizedBox(height: 2),
                                    Text('Switch the app to our Bliss & Salon look', style: TextStyle(color: Color(0xFF9F1239), fontSize: 11)),
                                  ],
                                ),
                              ),
                              Switch(
                                value: beautyMode,
                                activeColor: const Color(0xFFE11D48),
                                activeTrackColor: const Color(0xFFFECDD3),
                                inactiveThumbColor: Colors.grey.shade400,
                                inactiveTrackColor: Colors.grey.shade200,
                                onChanged: (_) => ref.read(beautyModeProvider.notifier).toggle(),
                              ),
                            ],
                          ),
                        ),
                        
                        // Menu Items
                        _MenuTile(
                          icon: Icons.developer_board, // Appliance like icon
                          label: 'Saved Appliances',
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SavedProductsScreen())),
                        ),
                        _MenuTile(
                          icon: Icons.notifications_none,
                          label: 'Notification Preferences',
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationPreferencesScreen())),
                        ),
                        _MenuTile(
                          icon: Icons.headset_mic_outlined,
                          label: 'Help & Support',
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportScreen())),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // --- Logout Button ---
                        InkWell(
                          onTap: () => _logout(context, ref),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.red, width: 1.5),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            alignment: Alignment.center,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.logout, color: Colors.red, size: 18),
                                SizedBox(width: 8),
                                Text('Logout', style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Failed to load profile: $err', style: const TextStyle(color: Colors.black54))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddressSheet(BuildContext context, WidgetRef ref, String customerId, {CustomerAddress? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
    await ref.read(pushNotificationServiceProvider).unregisterCurrentToken();
    await ref.read(authRepositoryProvider).logout();
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48), backgroundColor: const Color(0xFF16A34A)),
                onPressed: _saving ? null : _save,
                child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Address'),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: Colors.black54, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 13))),
              const Icon(Icons.chevron_right, color: Colors.black38, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
