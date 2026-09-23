import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import '../providers/customer_providers.dart';
import '../models/customer_models.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/service_browse_screen.dart';
import '../screens/notifications_screen.dart';
import '../theme/app_theme.dart';

class CustomTopBar extends ConsumerWidget {
  const CustomTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          _HeaderRow(),
          const SizedBox(height: 8),
          _LocationRow(profile: profile),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _SearchBar(),
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => Scaffold.of(context).openDrawer(),
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.menu_rounded, size: 28, color: Color(0xFF0F172A)),
            ),
          ),
          Image.asset(
            'assets/images/logocalls.png',
            height: 32, // Adjusted height for top bar
          ),
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none_rounded, size: 26, color: Color(0xFF0F172A)),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationRow extends ConsumerWidget {
  final AsyncValue profile;
  const _LocationRow({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: profile.when(
        data: (customer) {
          final c = customer as Customer;
          final addresses = c.addresses;
          final primary = addresses.isEmpty
              ? null
              : addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);

          final locationText = primary == null ? 'Select Location' : '${primary.city}, ${primary.state}';

          // The chevron here used to be decoration on a non-tappable Row —
          // it looked like a location switcher and did nothing. It now opens
          // the saved-address picker and writes the choice back through
          // isDefault, which is what the rest of the app reads.
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _openPicker(context, ref, c),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF16A34A), size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      locationText,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0F172A), size: 18),
                ],
              ),
            ),
          );
        },
        loading: () => const SizedBox(height: 20),
        error: (_, __) => const SizedBox(height: 20),
      ),
    );
  }

  void _openPicker(BuildContext context, WidgetRef ref, Customer customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _LocationPickerSheet(customer: customer),
    );
  }
}

class _LocationPickerSheet extends ConsumerStatefulWidget {
  final Customer customer;
  const _LocationPickerSheet({required this.customer});

  @override
  ConsumerState<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends ConsumerState<_LocationPickerSheet> {
  String? _saving;

  Future<void> _select(CustomerAddress address) async {
    if (address.isDefault) {
      Navigator.pop(context);
      return;
    }
    setState(() => _saving = address.id);
    final previousDefault = widget.customer.addresses
        .where((a) => a.isDefault)
        .map((a) => a.id)
        .firstOrNull;
    try {
      await ref.read(customerRepositoryProvider).setDefaultAddress(
            widget.customer.id,
            address.id,
            previousDefaultId: previousDefault,
          );
      ref.invalidate(myProfileProvider);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't change your location. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final addresses = widget.customer.addresses;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your location', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              'Used to find the branch that serves you.',
              style: TextStyle(fontSize: 12.5, color: AppColors.neutral500),
            ),
            const SizedBox(height: 14),
            if (addresses.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  "You haven't saved an address yet.",
                  style: TextStyle(fontSize: 13.5, color: AppColors.neutral500),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: addresses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _addressTile(addresses[i]),
                ),
              ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // EditProfileScreen owns the address book and has its own
                // back button; ProfileScreen is a bottom-tab screen and
                // pushing it as a route would strand the user.
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
              },
              icon: const Icon(Icons.add_location_alt_outlined, size: 18),
              label: const Text('Manage addresses'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addressTile(CustomerAddress address) {
    final selected = address.isDefault;
    final busy = _saving == address.id;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _saving != null ? null : () => _select(address),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF16A34A) : AppColors.neutral200,
            width: selected ? 1.5 : 1,
          ),
          color: selected ? const Color(0xFFF0FDF4) : AppColors.white,
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? const Color(0xFF16A34A) : AppColors.neutral500,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.label?.isNotEmpty == true ? address.label! : '${address.city}, ${address.state}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [address.line1, address.city, address.pinCode]
                        .where((v) => v != null && v.isNotEmpty)
                        .join(', '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.neutral500, height: 1.35),
                  ),
                ],
              ),
            ),
            if (busy)
              const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ServiceBrowseScreen()),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 4),
            const Icon(Icons.search_rounded, color: Color(0xFF16A34A), size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Search "AC Repair", "Cleaning"...',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              height: 18,
              width: 1.2,
              color: const Color(0xFFE2E8F0),
              margin: const EdgeInsets.symmetric(horizontal: 10),
            ),
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Voice search coming soon')),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic_none_rounded, color: Color(0xFF16A34A), size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
