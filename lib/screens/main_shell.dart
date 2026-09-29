import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_navigator.dart';
import '../providers/notification_providers.dart';
import '../providers/push_providers.dart';
import 'home_screen.dart';
import 'my_services_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  List<Widget> get _tabs => [
        const HomeScreen(),
        const SalonHomeScreen(),
        const HelpNowHomeScreen(),
        const MyServicesScreen(),
        const ProfileScreen(),
      ];

  @override
  void initState() {
    super.initState();
    ref.read(pushNotificationServiceProvider).initialize();
    pendingShellTab.addListener(_applyPendingTab);
    // A push may have been tapped while this shell was still being built
    // (cold start via getInitialMessage), so consume anything already queued.
    _applyPendingTab();
  }

  @override
  void dispose() {
    pendingShellTab.removeListener(_applyPendingTab);
    super.dispose();
  }

  // Tab switch requested from outside the widget tree — see app_navigator.dart.
  void _applyPendingTab() {
    final requested = pendingShellTab.value;
    if (requested == null) return;
    pendingShellTab.value = null;
    if (!mounted) return;
    setState(() => _index = requested);
    ref.invalidate(unreadNotificationCountProvider);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(foregroundPushMessageProvider, (previous, next) {
      final message = next.valueOrNull;
      if (message == null) return;
      // A push IS a new notification — the Alerts badge and list have to
      // reflect it without waiting for the user to pull-to-refresh.
      ref.invalidate(unreadNotificationCountProvider);
      ref.invalidate(myNotificationsProvider);

      final title = message.notification?.title;
      final body = message.notification?.body;
      if (body == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(title != null ? '$title: $body' : body),
          action: SnackBarAction(
            label: 'View',
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
        ),
      );
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: IndexedStack(index: _index, children: _tabs),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              height: 62,
              child: Row(
                children: [
                  _NavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home',
                    selected: _index == 0,
                    onTap: () => setState(() => _index = 0),
                  ),
                  _NavItem(
                    icon: Icons.spa_outlined,
                    activeIcon: Icons.spa_rounded,
                    label: 'Salon',
                    brandColor: const Color(0xFFEC4899),
                    selected: _index == 1,
                    onTap: () => setState(() => _index = 1),
                  ),
                  _NavItem(
                    icon: Icons.support_agent_outlined,
                    activeIcon: Icons.support_agent_rounded,
                    label: 'HelpNow',
                    brandColor: const Color(0xFFF97316),
                    selected: _index == 2,
                    onTap: () => setState(() => _index = 2),
                  ),
                  _NavItem(
                    icon: Icons.grid_view_outlined,
                    activeIcon: Icons.grid_view_rounded,
                    label: 'Bookings',
                    selected: _index == 3,
                    onTap: () => setState(() => _index = 3),
                  ),
                  _NavItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profile',
                    selected: _index == 4,
                    onTap: () => setState(() => _index = 4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _kNavGreen = Color(0xFF16A34A);
const _kNavIdle = Color(0xFF94A3B8);

// One tab: icon + label, always visible. The selected tab gets a short
// coloured bar along the top edge, a filled icon and a bold label. Salon and
// HelpNow ([brandColor]) always show in their own colour; the rest are grey
// until selected, then green.
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color? brandColor;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.brandColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = brandColor ?? _kNavGreen;
    final color = selected ? activeColor : (brandColor ?? _kNavIdle);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              width: selected ? 28 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(3)),
              ),
            ),
            const Spacer(),
            Icon(selected ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
