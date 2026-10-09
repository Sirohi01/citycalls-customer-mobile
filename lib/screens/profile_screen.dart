import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/profile_avatar.dart';
import '../models/customer_models.dart';
import '../providers/auth_providers.dart';
import '../providers/customer_providers.dart';
import '../providers/geo_providers.dart';
import '../providers/realtime_providers.dart';
import '../providers/push_providers.dart';
// import '../providers/theme_providers.dart'; // used by the hidden Preferences section
import '../widgets/state_views.dart';
import 'active_sessions_screen.dart';
import 'my_complaints_screen.dart';
import 'otp_request_screen.dart';
import 'saved_products_screen.dart';
import 'notification_preferences_screen.dart';
import 'support_screen.dart';
import 'edit_profile_screen.dart';

// Brand palette, matching the home header and the side drawer.
const _kDark = Color(0xFF0B0B0B);
const _kDark2 = Color(0xFF1C2A14);
const _kLime = Color(0xFF8BD450);
const _kGreen = Color(0xFF16A34A);
const _kInk = Color(0xFF0F172A);
const _kMuted = Color(0xFF64748B);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _open(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider);
    // final beautyMode = ref.watch(beautyModeProvider);  // Preferences hidden
    // Also used as the Profile bottom tab, where there's nothing to go back to.
    final canGoBack = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      // Light status-bar icons over the dark header.
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: profile.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: _kGreen)),
          error: (err, _) => Center(
            child: AppErrorView(
                error: err, onRetry: () => ref.invalidate(myProfileProvider)),
          ),
          data: (customer) => RefreshIndicator(
            color: _kGreen,
            onRefresh: () async => ref.invalidate(myProfileProvider),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _ProfileHeader(
                  customer: customer,
                  canGoBack: canGoBack,
                  onEdit: () => _open(context, const EditProfileScreen()),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Saved addresses ---
                      Row(
                        children: [
                          const Expanded(
                              child: _SectionLabel('Saved Addresses')),
                          Material(
                            color: _kGreen.withValues(alpha: 0.1),
                            shape: const StadiumBorder(),
                            child: InkWell(
                              customBorder: const StadiumBorder(),
                              onTap: () =>
                                  _showAddressSheet(context, ref, customer.id),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_rounded,
                                        size: 16, color: _kGreen),
                                    SizedBox(width: 4),
                                    Text('Add new',
                                        style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: _kGreen)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (customer.addresses.isEmpty)
                        _Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 22),
                            child: Column(
                              children: [
                                Icon(Icons.location_off_outlined,
                                    size: 32,
                                    color: _kMuted.withValues(alpha: 0.6)),
                                const SizedBox(height: 8),
                                const Text('No saved addresses yet',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _kInk)),
                                const SizedBox(height: 2),
                                const Text('Add one to book services faster.',
                                    style: TextStyle(
                                        fontSize: 12, color: _kMuted)),
                              ],
                            ),
                          ),
                        )
                      else
                        _Card(
                          child: Column(
                            children: [
                              for (int i = 0;
                                  i < customer.addresses.length;
                                  i++) ...[
                                if (i > 0) const _Hairline(indent: 64),
                                _AddressRow(
                                  address: customer.addresses[i],
                                  onEdit: () => _showAddressSheet(
                                      context, ref, customer.id,
                                      existing: customer.addresses[i]),
                                  onDelete: () => _confirmDeleteAddress(
                                      context,
                                      ref,
                                      customer.id,
                                      customer.addresses[i].id),
                                  onMakeDefault: () => _makeDefault(context,
                                      ref, customer, customer.addresses[i].id),
                                ),
                              ],
                            ],
                          ),
                        ),

                      // Preferences (Beauty Mode) — hidden for now; uncomment to bring back.
                      // const SizedBox(height: 22),
                      // const _SectionLabel('Preferences'),
                      // const SizedBox(height: 10),
                      // _Card(
                      //   child: Padding(
                      //     padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                      //     child: Row(
                      //       children: [
                      //         const _IconTile(
                      //             icon: Icons.spa_rounded,
                      //             color: Color(0xFFDB2777)),
                      //         const SizedBox(width: 12),
                      //         const Expanded(
                      //           child: Column(
                      //             crossAxisAlignment: CrossAxisAlignment.start,
                      //             children: [
                      //               Text('Beauty Mode',
                      //                   style: TextStyle(
                      //                       fontSize: 14.5,
                      //                       fontWeight: FontWeight.w600,
                      //                       color: _kInk)),
                      //               SizedBox(height: 2),
                      //               Text('Switch to our Bliss & Salon look',
                      //                   style: TextStyle(
                      //                       fontSize: 11.5, color: _kMuted)),
                      //             ],
                      //           ),
                      //         ),
                      //         Switch(
                      //           value: beautyMode,
                      //           activeColor: Colors.white,
                      //           activeTrackColor: const Color(0xFFDB2777),
                      //           onChanged: (_) => ref
                      //               .read(beautyModeProvider.notifier)
                      //               .toggle(),
                      //         ),
                      //       ],
                      //     ),
                      //   ),
                      // ),

                      const SizedBox(height: 22),
                      const _SectionLabel('Account'),
                      const SizedBox(height: 10),
                      _Card(
                        child: Column(
                          children: [
                            _MenuTile(
                              icon: Icons.kitchen_rounded,
                              color: const Color(0xFF2563EB),
                              label: 'Saved Appliances',
                              subtitle: 'Products you booked service for',
                              onTap: () =>
                                  _open(context, const SavedProductsScreen()),
                            ),
                            const _Hairline(indent: 64),
                            _MenuTile(
                              icon: Icons.notifications_none_rounded,
                              color: const Color(0xFFD97706),
                              label: 'Notification Preferences',
                              subtitle: 'WhatsApp, SMS and app alerts',
                              onTap: () => _open(context,
                                  const NotificationPreferencesScreen()),
                            ),
                            const _Hairline(indent: 64),
                            _MenuTile(
                              icon: Icons.devices_rounded,
                              color: const Color(0xFF7C3AED),
                              label: 'Signed-in Devices',
                              subtitle: 'Manage where you are logged in',
                              onTap: () =>
                                  _open(context, const ActiveSessionsScreen()),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),
                      const _SectionLabel('Support'),
                      const SizedBox(height: 10),
                      _Card(
                        child: Column(
                          children: [
                            _MenuTile(
                              icon: Icons.forum_outlined,
                              color: const Color(0xFFDC2626),
                              label: 'My Complaints',
                              subtitle: 'Track issues you raised',
                              onTap: () =>
                                  _open(context, const MyComplaintsScreen()),
                            ),
                            const _Hairline(indent: 64),
                            _MenuTile(
                              icon: Icons.headset_mic_outlined,
                              color: _kGreen,
                              label: 'Help & Support',
                              subtitle: 'FAQs and contact us',
                              onTap: () =>
                                  _open(context, const SupportScreen()),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmLogout(context, ref),
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text('Logout',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            backgroundColor: const Color(0xFFFEF2F2),
                            side: const BorderSide(color: Color(0xFFFECACA)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text('CityCalls · Built for brand services',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFF94A3B8))),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _makeDefault(BuildContext context, WidgetRef ref,
      Customer customer, String addressId) async {
    final previous =
        customer.addresses.where((a) => a.isDefault).firstOrNull?.id;
    try {
      await ref.read(customerRepositoryProvider).setDefaultAddress(
          customer.id, addressId,
          previousDefaultId: previous);
      ref.invalidate(myProfileProvider);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not set the default address. Try again.')));
    }
  }

  // Ask first — a stray tap shouldn't sign the user out.
  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('You will need to sign in again with an OTP.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _logout(context, ref);
  }

  void _showAddressSheet(BuildContext context, WidgetRef ref, String customerId,
      {CustomerAddress? existing}) {
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

  void _confirmDeleteAddress(BuildContext context, WidgetRef ref,
      String customerId, String addressId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref
                  .read(customerRepositoryProvider)
                  .deleteAddress(customerId, addressId);
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
  const _AddressFormSheet(
      {required this.customerId, this.existing, required this.onSaved});

  @override
  ConsumerState<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends ConsumerState<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _labelController =
      TextEditingController(text: widget.existing?.label);
  late final _line1Controller =
      TextEditingController(text: widget.existing?.line1);
  late final _line2Controller =
      TextEditingController(text: widget.existing?.line2);
  late final _landmarkController =
      TextEditingController(text: widget.existing?.landmark);
  late final _cityController =
      TextEditingController(text: widget.existing?.city);
  late final _stateController =
      TextEditingController(text: widget.existing?.state);
  late final _pinCodeController =
      TextEditingController(text: widget.existing?.pinCode);
  bool _saving = false;
  bool _lookingUpPin = false;
  String? _error;
  String? _pinNotice;
  late String _lastLookedUpPin = widget.existing?.pinCode ?? '';

  @override
  void initState() {
    super.initState();
    _pinCodeController.addListener(_onPinChanged);
  }

  // Same GET /geo/pincode/:pincode autofill the booking flow's address sheet
  // uses — kept identical here so a saved address and a booking address are
  // never resolved by two different rules.
  void _onPinChanged() {
    final pin = _pinCodeController.text.trim();
    if (pin.length != 6 || pin == _lastLookedUpPin) return;
    _lastLookedUpPin = pin;
    _lookupPin(pin);
  }

  Future<void> _lookupPin(String pin) async {
    setState(() {
      _lookingUpPin = true;
      _pinNotice = null;
    });
    final area = await ref.read(geoRepositoryProvider).lookupPincode(pin);
    if (!mounted || _pinCodeController.text.trim() != pin) return;
    setState(() {
      _lookingUpPin = false;
      if (area == null) return;
      // Fill blanks only — never overwrite what the user typed.
      if (_cityController.text.trim().isEmpty && area.resolvedCity != null) {
        _cityController.text = area.resolvedCity!;
      }
      if (_stateController.text.trim().isEmpty && area.state != null) {
        _stateController.text = area.state!;
      }
      _pinNotice = area.serviceable
          ? 'We serve this area${area.branchName != null ? ' · ${area.branchName}' : ''}'
          : "We don't cover this PIN code yet — you can still save the address.";
    });
  }

  @override
  void dispose() {
    _pinCodeController.removeListener(_onPinChanged);
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
      padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.existing != null ? 'Edit Address' : 'Add Address',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _labelController,
                  decoration: const InputDecoration(
                      labelText: 'Label (e.g. Home, Office)')),
              const SizedBox(height: 10),
              TextFormField(
                controller: _line1Controller,
                decoration:
                    const InputDecoration(labelText: 'House / Flat / Street'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                  controller: _line2Controller,
                  decoration:
                      const InputDecoration(labelText: 'Area (optional)')),
              const SizedBox(height: 10),
              TextFormField(
                  controller: _landmarkController,
                  decoration:
                      const InputDecoration(labelText: 'Landmark (optional)')),
              const SizedBox(height: 10),
              TextFormField(
                controller: _pinCodeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'PIN Code',
                  counterText: '',
                  helperText: 'City and state fill in automatically',
                  suffixIcon: _lookingUpPin
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : null,
                ),
                validator: (v) => (v == null || v.trim().length < 6)
                    ? 'Enter a valid 6-digit PIN code'
                    : null,
              ),
              if (_pinNotice != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 4),
                  child: Text(
                    _pinNotice!,
                    style: TextStyle(
                      fontSize: 12,
                      color: _pinNotice!.startsWith('We serve')
                          ? const Color(0xFF16A34A)
                          : Colors.orange.shade800,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'City'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(labelText: 'State'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              if (_error != null)
                Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.red))),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: const Color(0xFF16A34A)),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Save Address'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Dark brand header with the photo, name and contact details.
class _ProfileHeader extends StatelessWidget {
  final Customer customer;
  final bool canGoBack;
  final VoidCallback onEdit;
  const _ProfileHeader({
    required this.customer,
    required this.canGoBack,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 8, 16, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kDark, _kDark2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: Row(
              children: [
                if (canGoBack)
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.08)),
                  )
                else
                  const SizedBox(width: 8),
                const Expanded(
                  child: Text('My Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
                IconButton(
                  onPressed: onEdit,
                  tooltip: 'Edit profile',
                  icon: const Icon(Icons.edit_outlined,
                      color: Colors.white, size: 19),
                  style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.08)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onEdit,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [_kLime, _kGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                  ),
                  child: const ProfileAvatar(
                      size: 88, borderWidth: 3, borderColor: _kDark),
                ),
                Positioned(
                  right: 0,
                  bottom: 2,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _kLime,
                      shape: BoxShape.circle,
                      border: Border.all(color: _kDark, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 14, color: _kDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            customer.name.isNotEmpty ? customer.name : 'Guest User',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (customer.mobile != null && customer.mobile!.isNotEmpty)
                _InfoChip(
                    icon: Icons.phone_rounded, text: '+91 ${customer.mobile}'),
              if (customer.email != null && customer.email!.isNotEmpty)
                _InfoChip(icon: Icons.email_rounded, text: customer.email!),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _kLime),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12, color: Colors.white.withValues(alpha: 0.85))),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Color(0xFF94A3B8),
          ),
        ),
      );
}

// White rounded card that groups rows.
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
}

class _Hairline extends StatelessWidget {
  final double indent;
  const _Hairline({required this.indent});

  @override
  Widget build(BuildContext context) => Divider(
      height: 1, thickness: 1, indent: indent, color: const Color(0xFFF1F5F9));
}

class _IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconTile({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      );
}

class _AddressRow extends StatelessWidget {
  final CustomerAddress address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMakeDefault;
  const _AddressRow({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onMakeDefault,
  });

  @override
  Widget build(BuildContext context) {
    final label = (address.label ?? '').trim();
    final lower = label.toLowerCase();
    final (IconData icon, Color color) = lower == 'home'
        ? (Icons.home_rounded, _kGreen)
        : lower == 'office' || lower == 'work'
            ? (Icons.business_rounded, const Color(0xFF4338CA))
            : (Icons.location_on_rounded, const Color(0xFFD97706));
    final details = [
      address.line1,
      address.line2,
      address.landmark,
      address.city,
      address.state,
      address.pinCode,
    ].where((s) => s != null && s.trim().isNotEmpty).join(', ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconTile(icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        label.isNotEmpty ? label : 'Address',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: _kInk),
                      ),
                    ),
                    if (address.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Default',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _kGreen)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(details,
                    style: const TextStyle(
                        fontSize: 12.5, height: 1.35, color: _kMuted)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                size: 20, color: Color(0xFF94A3B8)),
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'default') onMakeDefault();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              if (!address.isDefault)
                const PopupMenuItem(
                    value: 'default', child: Text('Set as default')),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  const _MenuTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            _IconTile(icon: icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: _kInk)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 11.5, color: _kMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFCBD5E1), size: 22),
          ],
        ),
      ),
    );
  }
}
