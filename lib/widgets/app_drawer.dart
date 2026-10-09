import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
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
      backgroundColor: const Color(0xFFF8FAFC),
      surfaceTintColor: Colors.transparent,
      // A proper side panel: most of the screen, with the page still visible
      // (and tappable to close) on the right.
      width: screenWidth * 0.86,
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                    const SizedBox(width: 10),
                    _QuickAction(
                      icon: Icons.favorite_rounded,
                      label: 'Favourites',
                      color: const Color(0xFFE11D48),
                      onTap: () => _open(context, const FavouritesScreen()),
                    ),
                    const SizedBox(width: 10),
                    _QuickAction(
                      icon: Icons.headset_mic_rounded,
                      label: 'Support',
                      color: _kGreen,
                      onTap: () => _open(context, const SupportScreen()),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
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
                    icon: Icons.spa_rounded,
                    title: 'Salon at Home',
                    subtitle: 'Beauty & grooming services',
                    iconColor: const Color(0xFFDB2777),
                    onTap: () => _goToTab(context, ShellTab.salon),
                  ),
                  _MenuListItem(
                    icon: Icons.support_agent_rounded,
                    title: 'HelpNow',
                    subtitle: 'Quick help for everyday chores',
                    iconColor: const Color(0xFFD97706),
                    onTap: () => _goToTab(context, ShellTab.helpNow),
                  ),
                ]),
                const SizedBox(height: 18),
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
                const SizedBox(height: 18),
                const _SectionLabel('Help'),
                _MenuGroup(children: [
                  _MenuListItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    subtitle: 'FAQs, complaints and contact',
                    onTap: () => _open(context, const SupportScreen()),
                  ),
                ]),
                const SizedBox(height: 18),
                _ReferCard(onTap: () => _shareApp(context)),
                const SizedBox(height: 8),
              ],
            ),
          ),
          // Logout pinned to the bottom.
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'CityCalls · Built for brand services',
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
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626)),
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
      padding: EdgeInsets.fromLTRB(20, top + 12, 12, 22),
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
                            color: Colors.white,
                            fontWeight: FontWeight.w500)),
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
          const SizedBox(height: 18),
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
                        size: 58, borderWidth: 2, borderColor: _kDark),
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
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 8),
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
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 62,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: _kInk,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11.5, color: _kMuted),
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

class _ReferCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ReferCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF16A34A), Color(0xFF4FA021)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _kGreen.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.card_giftcard_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Refer & Earn',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                SizedBox(height: 3),
                Text('Share CityCalls with friends & family',
                    style: TextStyle(fontSize: 11.5, color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.white,
            shape: const StadiumBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder: const StadiumBorder(),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Text('Invite',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _kGreen)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Play Store listing for this app (applicationId com.citycalls.customer).
const _kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.citycalls.customer';

// Opens the system share sheet (WhatsApp, SMS, etc.) with an invite message.
// There is no referral/rewards backend yet, so this is a plain invite.
Future<void> _shareApp(BuildContext context) async {
  final box = context.findRenderObject() as RenderBox?;
  await Share.share(
    'I use CityCalls to book trusted professionals for home services '
    '— AC repair, cleaning, pest control, salon at home and more. '
    'Download the app: $_kPlayStoreUrl',
    subject: 'Try CityCalls',
    // iPad needs an anchor for the share popover.
    sharePositionOrigin:
        box == null ? null : box.localToGlobal(Offset.zero) & box.size,
  );
}
