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
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late int _index = widget.initialIndex;
  // Tabs visited before the current one, most recent last. The phone's back
  // button walks back through these one at a time instead of closing the app.
  final List<int> _tabHistory = [];

  void _selectTab(int index) {
    if (index == _index) return;
    setState(() {
      _tabHistory
        ..remove(_index)
        ..add(_index);
      _index = index;
    });
  }

  // Back: previous tab first, then Home, and only then let the app close.
  void _handleBack() {
    setState(() {
      if (_tabHistory.isNotEmpty) {
        _index = _tabHistory.removeLast();
      } else {
        _index = 0;
      }
    });
  }

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
    pendingShellTab.addListener(_applyPendingTab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(pushNotificationServiceProvider).initialize();
      // A push may have been tapped while this shell was still being built
      // (cold start via getInitialMessage), so consume anything already queued.
      _applyPendingTab();
    });
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
    _selectTab(requested);
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
        systemNavigationBarColor: Color(0xFFF7F8FA),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      // Pushed screens (service detail, booking steps…) pop on their own
      // before this is reached; here back only switches tabs.
      child: PopScope(
        canPop: _tabHistory.isEmpty && _index == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _handleBack();
        },
        child: Scaffold(
          body: IndexedStack(index: _index, children: _tabs),
          bottomNavigationBar: _BottomNavBar(
            currentIndex: _index,
            onSelect: _selectTab,
          ),
        ),
      ),
    );
  }
}

const _kNavGreen = Color(0xFF16A34A);
const _kNavInk = Color(0xFF0F172A);
const _kNavIdle = Color(0xFF94A3B8);

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;
  const _BottomNavBar({
    required this.currentIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(14, 8, 14, bottom > 0 ? bottom : 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 26,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                selected: currentIndex == 0,
                onTap: () => onSelect(0),
              ),
              _NavItem(
                icon: Icons.content_cut_outlined,
                activeIcon: Icons.content_cut_rounded,
                label: 'Salon',
                brandColor: const Color(0xFFEC4899),
                selected: currentIndex == 1,
                onTap: () => onSelect(1),
              ),
              _NavItem(
                icon: Icons.bolt_outlined,
                activeIcon: Icons.bolt_rounded,
                label: 'HelpNow',
                brandColor: const Color(0xFF0F766E),
                selected: currentIndex == 2,
                onTap: () => onSelect(2),
              ),
              _NavItem(
                icon: Icons.assignment_outlined,
                activeIcon: Icons.assignment_rounded,
                label: 'Bookings',
                selected: currentIndex == 3,
                onTap: () => onSelect(3),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                selected: currentIndex == 4,
                onTap: () => onSelect(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    final color = selected ? activeColor : _kNavIdle;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: selected
                ? activeColor.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: selected ? 30 : 20,
                height: 3,
                decoration: BoxDecoration(
                  color: selected ? activeColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 8),
              AnimatedScale(
                scale: selected ? 1.08 : 1,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: Icon(
                  selected ? activeIcon : icon,
                  color: color,
                  size: 21.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: selected ? 10.8 : 10.2,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? _kNavInk : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
