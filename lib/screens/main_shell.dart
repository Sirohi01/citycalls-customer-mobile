import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  static const _tabs = [
    HomeScreen(),
    _BlissSalonTab(),
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
                const BottomNavigationBarItem(
                  // The image uses a bell for Alerts
                  icon: Padding(
                      padding: EdgeInsets.only(bottom: 4, top: 8),
                      child: Icon(Icons.notifications_none)),
                  activeIcon: Padding(
                      padding: EdgeInsets.only(bottom: 4, top: 8),
                      child: Icon(Icons.notifications)),
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

class _BlissSalonTab extends ConsumerWidget {
  const _BlissSalonTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We import providers from service_browse_screen conceptually or provider file
    final categoriesAsync = ref.watch(serviceCategoriesProvider);

    return categoriesAsync.when(
      data: (cats) {
        final blissCat = cats.where((c) => c.label.toLowerCase().contains('bliss') || c.label.toLowerCase().contains('salon')).firstOrNull;
        if (blissCat != null) {
          return ServiceBrowseScreen(initialCategoryId: blissCat.id);
        }
        return const Scaffold(body: Center(child: Text('Salon services not available')));
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF16A34A)))),
      error: (_, __) => const Scaffold(body: Center(child: Text('Error loading salon services'))),
    );
  }
}
