import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/customer_providers.dart';
import '../providers/auth_providers.dart';
import '../providers/push_providers.dart';
import '../providers/realtime_providers.dart';
import '../screens/profile_screen.dart';
import '../screens/support_screen.dart';
import '../screens/favourites_screen.dart';
import 'profile_avatar.dart';
import '../screens/otp_request_screen.dart';
import '../screens/service_browse_screen.dart';
import '../app_navigator.dart';

// Brand palette, matching the home header (dark) and CityCalls green.
const _kDark = Color(0xFF0B0B0B);
const _kDark2 = Color(0xFF1C2A14);
const _kLime = Color(0xFF8BD450);
const _kGreen = Color(0xFF16A34A);
const _kInk = Color(0xFF0F172A);
const _kMuted = Color(0xFF64748B);

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  // Close the drawer, then open [screen] on top of the current tab.
  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  // Close the drawer and switch MainShell to a bottom tab.
  void _goToTab(BuildContext context, int tab) {
    Navigator.of(context).pop();
    pendingShellTab.value = tab;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Drawer(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      // A proper side panel: most of the screen, with the page still visible
      // (and tappable to close) on the right.
      width: screenWidth * 0.78,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _DrawerHeader(
            onClose: () => Navigator.of(context).pop(),
            onProfile: () => _open(context, const ProfileScreen()),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              physics: const BouncingScrollPhysics(),
              children: [
                // Quick actions
                Row(
                  children: [
                    _QuickAction(
                      icon: Icons.receipt_long_rounded,
                      label: 'Bookings',
                      color: const Color(0xFF2563EB),
                      onTap: () => _goToTab(context, ShellTab.bookings),
                    ),
                    const SizedBox(width: 8),
                    _QuickAction(
                      icon: Icons.favorite_rounded,
                      label: 'Favourites',
                      color: const Color(0xFFE11D48),
                      onTap: () => _open(context, const FavouritesScreen()),
                    ),
                    const SizedBox(width: 8),
                    _QuickAction(
                      icon: Icons.headset_mic_rounded,
                      label: 'Support',
                      color: _kGreen,
                      onTap: () => _open(context, const SupportScreen()),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const _SectionLabel('Explore'),
                _MenuGroup(children: [
                  _MenuListItem(
                    icon: Icons.grid_view_rounded,
                    title: 'All Categories',
                    subtitle: 'Browse every service we offer',
                    onTap: () => _open(context,
                        const ServiceBrowseScreen(title: 'All Categories')),
                  ),
                  _MenuListItem(
                    icon: Icons.content_cut_rounded,
                    title: 'Salon at Home',
                    subtitle: 'Beauty & grooming services',
                    iconColor: const Color(0xFFDB2777),
                    onTap: () => _goToTab(context, ShellTab.salon),
                  ),
                  _MenuListItem(
                    icon: Icons.bolt_rounded,
                    title: 'HelpNow',
                    subtitle: 'Quick help for everyday chores',
                    iconColor: const Color(0xFF0F766E),
                    onTap: () => _goToTab(context, ShellTab.helpNow),
                  ),
                ]),
                const SizedBox(height: 10),
                const _SectionLabel('Account'),
                _MenuGroup(children: [
                  _MenuListItem(
                    icon: Icons.person_outline_rounded,
                    title: 'My Profile',
                    subtitle: 'Name, email and photo',
                    onTap: () => _open(context, const ProfileScreen()),
                  ),
                  _MenuListItem(
                    icon: Icons.location_on_outlined,
                    title: 'My Addresses',
                    subtitle: 'Saved service locations',
                    onTap: () => _open(context, const ProfileScreen()),
                  ),
                  _MenuListItem(
                    icon: Icons.favorite_border_rounded,
                    title: 'My Favourites',
                    subtitle: 'Services you saved',
                    onTap: () => _open(context, const FavouritesScreen()),
                  ),
                ]),
                const SizedBox(height: 10),
                const _SectionLabel('Help'),
                _MenuGroup(children: [
                  _MenuListItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    subtitle: 'FAQs, complaints and contact',
                    onTap: () => _open(context, const SupportScreen()),
                  ),
                ]),
                const SizedBox(height: 8),
              ],
            ),
          ),
          // Logout pinned to the bottom.
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
              child: Column(
                children: [
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
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'CityCalls Built for brand services',
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

// Dark brand header: wordmark + close, then the customer's photo, name and
// number. Tapping the profile row opens My Profile.
class _DrawerHeader extends ConsumerWidget {
  final VoidCallback onClose;
  final VoidCallback onProfile;
  const _DrawerHeader({required this.onClose, required this.onProfile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider);
    final top = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 8, 8, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kDark, _kDark2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    height: 1,
                  ),
                  children: [
                    TextSpan(text: 'City', style: TextStyle(color: _kLime)),
                    TextSpan(
                        text: 'Calls',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onClose,
                tooltip: 'Close',
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: onProfile,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                          colors: [_kLime, _kGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                    ),
                    child: const ProfileAvatar(
                        size: 52, borderWidth: 2, borderColor: _kDark),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: profile.when(
                      data: (c) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name.isNotEmpty ? c.name : 'Guest User',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            c.mobile != null && c.mobile!.isNotEmpty
                                ? '+91 ${c.mobile}'
                                : '',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: _kLime.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _kLime.withValues(alpha: 0.5)),
                            ),
                            child: const Text(
                              'View profile',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _kLime,
                              ),
                            ),
                          ),
                        ],
                      ),
                      loading: () => const _HeaderLine(width: 140),
                      error: (_, __) => const Text('Couldn\'t load profile',
                          style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: Colors.white.withValues(alpha: 0.6)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Placeholder bar while the profile loads.
class _HeaderLine extends StatelessWidget {
  final double width;
  const _HeaderLine({required this.width});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: 14,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
      );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kInk,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 5),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Color(0xFF94A3B8),
          ),
        ),
      );
}

// White rounded card holding a few menu rows separated by hairlines.
class _MenuGroup extends StatelessWidget {
  final List<Widget> children;
  const _MenuGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 54,
                  color: Color(0xFFF1F5F9)),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _MenuListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;

  const _MenuListItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor = _kGreen,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.8,
                      fontWeight: FontWeight.w600,
                      color: _kInk,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: _kMuted),
                  ),
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
