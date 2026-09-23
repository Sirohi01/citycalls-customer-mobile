import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_navigator.dart';
import '../providers/notification_providers.dart';
import '../providers/push_providers.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'my_services_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'service_browse_screen.dart';
import '../providers/catalog_providers.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  List<Widget> get _tabs => [
    const HomeScreen(),
    _BlissSalonTab(onBack: () => setState(() => _index = 0)),
    const MyServicesScreen(),
    const NotificationsScreen(),
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
            onPressed: () => setState(() => _index = ShellTab.alerts),
          ),
        ),
      );
    });

    final unreadCount = ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0;

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
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: BottomNavigationBar(
              currentIndex: _index,
              onTap: (i) {
                // Captured before setState — comparing _index afterwards
                // would just be comparing i to itself.
                final leavingAlerts = _index == ShellTab.alerts && i != ShellTab.alerts;
                setState(() => _index = i);
                // Opening Alerts marks rows read as they're tapped, and
                // leaving it is the natural moment to re-sync the count.
                if (i == ShellTab.alerts || leavingAlerts) {
                  ref.invalidate(unreadNotificationCountProvider);
                }
              },
              backgroundColor: AppColors.white,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              // The exact green color from the image
              selectedItemColor: const Color(0xFF16A34A),
              unselectedItemColor: const Color(0xFF9CA3AF),
              selectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              iconSize: 24,
              items: [
                const BottomNavigationBarItem(
                  icon: Padding(
                      padding: EdgeInsets.only(bottom: 4, top: 8),
                      child: Icon(Icons.home_outlined)),
                  activeIcon: Padding(
                      padding: EdgeInsets.only(bottom: 4, top: 8),
                      child: Icon(Icons.home)),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                      padding: const EdgeInsets.only(bottom: 4, top: 4),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.pink.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.spa_outlined, color: Colors.pink, size: 20),
                      ),
                  ),
                  activeIcon: Padding(
                      padding: const EdgeInsets.only(bottom: 4, top: 4),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.pink,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.pink.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: const Icon(Icons.spa, color: Colors.white, size: 20),
                      ),
                  ),
                  label: 'Salon',
                ),
                const BottomNavigationBarItem(
                  // The image uses a 4-square grid for Services
                  icon: Padding(
                      padding: EdgeInsets.only(bottom: 4, top: 8),
                      child: Icon(Icons.grid_view_outlined)),
                  activeIcon: Padding(
                      padding: EdgeInsets.only(bottom: 4, top: 8),
                      child: Icon(Icons.grid_view_rounded)),
                  label: 'Bookings',
                ),
                BottomNavigationBarItem(
                  // The image uses a bell for Alerts
                  icon: Padding(
                      padding: const EdgeInsets.only(bottom: 4, top: 8),
                      child: _UnreadBadge(count: unreadCount, child: const Icon(Icons.notifications_none))),
                  activeIcon: Padding(
                      padding: const EdgeInsets.only(bottom: 4, top: 8),
                      child: _UnreadBadge(count: unreadCount, child: const Icon(Icons.notifications))),
                  label: 'Alerts',
                ),
                const BottomNavigationBarItem(
                  icon: Padding(
                      padding: EdgeInsets.only(bottom: 4, top: 8),
                      child: Icon(Icons.person_outline)),
                  activeIcon: Padding(
                      padding: EdgeInsets.only(bottom: 4, top: 8),
                      child: Icon(Icons.person)),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;
  final Widget child;
  const _UnreadBadge({required this.count, required this.child});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -6,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            constraints: const BoxConstraints(minWidth: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.white, width: 1.5),
            ),
            child: Text(
              count > 99 ? '99+' : '$count',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700, height: 1.3),
            ),
          ),
        ),
      ],
    );
  }
}

class _BlissSalonTab extends ConsumerWidget {
  final VoidCallback? onBack;
  const _BlissSalonTab({this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We import providers from service_browse_screen conceptually or provider file
    final categoriesAsync = ref.watch(serviceCategoriesProvider);

    return categoriesAsync.when(
      data: (cats) {
        final blissCat = cats.where((c) => c.label.toLowerCase().contains('bliss') || c.label.toLowerCase().contains('salon')).firstOrNull;
        if (blissCat != null) {
          return ServiceBrowseScreen(initialCategoryId: blissCat.id, title: 'Salon Services', onBack: onBack);
        }
        return const Scaffold(body: Center(child: Text('Salon services not available')));
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF16A34A)))),
      error: (_, __) => const Scaffold(body: Center(child: Text('Error loading salon services'))),
    );
  }
}
