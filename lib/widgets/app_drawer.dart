import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/customer_providers.dart';
import '../providers/auth_providers.dart';
import '../models/customer_models.dart';
import '../screens/profile_screen.dart';
import '../screens/service_browse_screen.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider);

    return Drawer(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.zero,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header (Logo and Close Button)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'City',
                          style: TextStyle(
                            color: Color(0xFF16A34A),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: 'Calls',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF0F172A), size: 24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  ),
                ],
              ),
            ),

            // Profile Section
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFFF1F5F9),
                      child: ClipOval(
                        child: Image.network(
                          'https://api.dicebear.com/7.x/notionists/png?seed=rohit', // Placeholder for avatar
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Color(0xFF94A3B8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: profile.when(
                        data: (customer) {
                          final c = customer as Customer;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.name.isNotEmpty ? c.name : 'Guest User',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                c.mobile ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          );
                        },
                        loading: () => const Text('Loading...'),
                        error: (_, __) => const Text('Error loading profile'),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 22),
                  ],
                ),
              ),
            ),

            // Refer & Earn Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDCFCE7), width: 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFF16A34A), size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Refer & Earn', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                          SizedBox(height: 2),
                          Text('Invite friends and\nearn exciting rewards', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF475569))),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                physics: const BouncingScrollPhysics(),
                children: [
                  _DrawerItem(icon: Icons.home_rounded, title: 'Home', isActive: true, onTap: () => Navigator.of(context).pop()),
                  _DrawerItem(icon: Icons.calendar_month_rounded, title: 'Bookings', onTap: () {}),
                  _DrawerItem(icon: Icons.home_repair_service_outlined, title: 'My Services', onTap: () {}),
                  _DrawerItem(icon: Icons.account_balance_wallet_outlined, title: 'Wallet', onTap: () {}),
                  _DrawerItem(icon: Icons.local_offer_outlined, title: 'Offers & Discounts', onTap: () {}),
                  _DrawerItem(icon: Icons.people_outline_rounded, title: 'Refer & Earn', onTap: () {}),
                  _DrawerItem(icon: Icons.location_on_outlined, title: 'My Address', onTap: () {}),
                  _DrawerItem(icon: Icons.headset_mic_outlined, title: 'Help & Support', onTap: () {}),
                  _DrawerItem(icon: Icons.notifications_none_rounded, title: 'Notifications', hasDot: true, onTap: () {}),
                  _DrawerItem(icon: Icons.settings_outlined, title: 'Settings', onTap: () {}),
                  const SizedBox(height: 16),
                  
                  // Logout
                  InkWell(
                    onTap: () {
                      // TODO: Implement logout in auth provider
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 22),
                          SizedBox(width: 16),
                          Text('Logout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Help Banner & Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFDCFCE7), width: 1),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.support_agent_rounded, color: Color(0xFF16A34A), size: 26),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Need Help?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                              SizedBox(height: 2),
                              Text('We are here to help you', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF475569))),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'CityCalls v1.0.0',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final bool hasDot;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isActive = false,
    this.hasDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF0FDF4) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF16A34A) : const Color(0xFF475569),
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  color: isActive ? const Color(0xFF16A34A) : const Color(0xFF0F172A),
                ),
              ),
            ),
            if (hasDot)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  shape: BoxShape.circle,
                ),
              ),
            Icon(Icons.chevron_right_rounded, color: isActive ? Colors.transparent : const Color(0xFFCBD5E1), size: 20),
          ],
        ),
      ),
    );
  }
}
