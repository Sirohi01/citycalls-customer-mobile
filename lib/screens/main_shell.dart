import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/push_providers.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'my_services_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

// Bottom navigation shell — Home, My Services, Notifications, Profile, per
// docs/rohit/05-customer-app-screen-list.md "Tab Structure". Also where push
// notification setup lives: MainShell is only ever reached after a
// successful login (splash/OTP-verify routing), so it's a natural single
// place to request notification permission + register the FCM token once
// per session, rather than duplicating that call at both login call sites.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  static const _tabs = [
    HomeScreen(),
    MyServicesScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    ref.read(pushNotificationServiceProvider).initialize();
  }

  @override
  Widget build(BuildContext context) {
    // Foreground messages don't produce a system notification banner on
    // their own (that's OS behavior for background/terminated apps only) —
    // shown as an in-app SnackBar instead, since the user is already looking
    // at the app when these arrive.
    ref.listen(foregroundPushMessageProvider, (previous, next) {
      final message = next.valueOrNull;
      final title = message?.notification?.title;
      final body = message?.notification?.body;
      if (body == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(title != null ? '$title: $body' : body)),
      );
    });

    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.neutral100,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.build_outlined), selectedIcon: Icon(Icons.build), label: 'My Services'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Notifications'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
