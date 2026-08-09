import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/push_providers.dart';
import '../theme/app_theme.dart';
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
    ref.listen(foregroundPushMessageProvider, (previous, next) {
      final message = next.valueOrNull;
      final title = message?.notification?.title;
      final body = message?.notification?.body;
      if (body == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(title != null ? '$title: $body' : body)),
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
              onTap: (i) => setState(() => _index = i),
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
              items: const [
                BottomNavigationBarItem(
                  icon: Padding(
                      padding: EdgeInsets.only(bottom: 4, top: 8),
                      child: Icon(Icons.home_outlined)),
                  activeIcon: Padding(
                      padding: EdgeInsets.only(bottom: 4, top: 8),
                      child: Icon(Icons.home)),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  // The image uses a 4-square grid for Services
                  icon: Padding(
                      padding: EdgeInsets.only(bottom: 4, top: 8),
                      child: Icon(Icons.grid_view_outlined)),
                  activeIcon: Padding(
                      padding: EdgeInsets.only(bottom: 4, top: 8),
                      child: Icon(Icons.grid_view_rounded)),
                  label: 'Services',
                ),
                BottomNavigationBarItem(
                  // The image uses a bell for Alerts
                  icon: Padding(
                      padding: EdgeInsets.only(bottom: 4, top: 8),
                      child: Icon(Icons.notifications_none)),
                  activeIcon: Padding(
                      padding: EdgeInsets.only(bottom: 4, top: 8),
                      child: Icon(Icons.notifications)),
                  label: 'Alerts',
                ),
                BottomNavigationBarItem(
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
