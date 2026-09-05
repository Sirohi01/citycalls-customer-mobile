import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer_models.dart';
import '../providers/customer_providers.dart';
import '../providers/auth_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(myProfileProvider).value;
    _nameController = TextEditingController(text: profile?.name ?? '');
    _emailController = TextEditingController(text: profile?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final profile = ref.read(myProfileProvider).value;
    if (profile == null) return;
    
    setState(() {
      _saving = true;
      _error = null;
    });
    
    try {
      await ref.read(customerRepositoryProvider).updateProfile(
            profile.id,
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
          );
      ref.invalidate(myProfileProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to save changes. Please try again.';
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(myProfileProvider).value;
    
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
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
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Edit Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87)),
                          SizedBox(height: 2),
                          Text('Update your information', style: TextStyle(color: Colors.black54, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    children: [
                      // --- Profile Photo Card ---
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F5132),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFE6F4EA), width: 4),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE6F4EA),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(Icons.camera_alt_outlined, size: 14, color: Color(0xFF0F5132)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Profile Photo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  const SizedBox(height: 4),
                                  const Text('Tap to change your profile photo', style: TextStyle(color: Colors.black54, fontSize: 12)),
                                  const SizedBox(height: 12),
                                  InkWell(
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo change is coming soon!')));
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE6F4EA),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.camera_alt_outlined, size: 14, color: Color(0xFF16A34A)),
                                          SizedBox(width: 6),
                                          Text('Change Photo', style: TextStyle(color: Color(0xFF16A34A), fontSize: 12, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // --- Form Fields ---
                      const Text('Full Name', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outline, color: Colors.black54, size: 20),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5)),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      const Text('Phone Number', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.transparent),
                        ),
                        child: TextField(
                          controller: TextEditingController(text: '+91 ${profile.mobile ?? ''}'),
                          readOnly: true,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.phone_outlined, color: Colors.black54, size: 20),
                            suffixIcon: Icon(Icons.lock_outline, color: Colors.black45, size: 18),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text('Phone number cannot be changed.', style: TextStyle(color: Colors.black45, fontSize: 11)),
                      
                      const SizedBox(height: 20),
                      
                      const Text('Email Address', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF16A34A), size: 20),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5)),
                        ),
                      ),
                      
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                      ],
                      
                      const SizedBox(height: 32),
                      
                      // --- Saved Addresses Header ---
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
                            onTap: () => _showAddressSheet(context, ref, profile.id),
                            child: const Row(
                              children: [
                                Icon(Icons.add, color: Color(0xFF16A34A), size: 14),
                                SizedBox(width: 2),
                                Text('Add New', style: TextStyle(color: Color(0xFF16A34A), fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Same logic as Profile screen for rendering addresses
                      if (profile.addresses.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: const Text('No saved addresses yet.', style: TextStyle(color: Colors.black54, fontSize: 13)),
                        )
                      else
                        ...profile.addresses.map((a) {
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
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(iconData, size: 20, color: const Color(0xFF16A34A)),
                                ),
                                const SizedBox(width: 12),
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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, size: 18, color: Colors.black87),
                                      padding: EdgeInsets.zero,
                                      onSelected: (value) {
                                        if (value == 'edit') _showAddressSheet(context, ref, profile.id, existing: a);
                                        else if (value == 'delete') _confirmDeleteAddress(context, ref, profile.id, a.id);
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                                      ],
                                    ),
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
                        
                      const SizedBox(height: 40), // Spacing for sticky bottom
                    ],
                  ),
                ),
                
                // --- Sticky Bottom Actions ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFF16A34A), width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: const Text('Cancel', style: TextStyle(color: Color(0xFF16A34A), fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: _saving ? null : _saveChanges,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: _saving
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Same helper methods for addresses (Ideally we'd extract these out, but for immediate exact mockup they are kept simple)
  void _showAddressSheet(BuildContext context, WidgetRef ref, String customerId, {CustomerAddress? existing}) {
    // Requires a small helper widget for the form which is likely in profile_screen.dart, 
    // but to avoid duplication we could just show a simple snackbar or copy the form.
    // For now, we will notify that address management is on the main profile screen if needed, 
    // or we can just pop and let them manage there. Let's just prompt them.
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address management is available on the main Profile screen')));
  }

  void _confirmDeleteAddress(BuildContext context, WidgetRef ref, String customerId, String addressId) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address management is available on the main Profile screen')));
  }
}
