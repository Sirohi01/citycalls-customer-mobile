import 'package:flutter/material.dart';

// The app has no router package — navigation is imperative Navigator.push
// everywhere (see screens/). Two things still need to navigate from outside
// a widget's BuildContext: an expired session (api_client.dart) and a tapped
// push notification (data/push_notification_service.dart). This key is how
// they reach the navigator.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

NavigatorState? get appNavigator => appNavigatorKey.currentState;

// Bottom-tab indices in MainShell, named so callers outside that file don't
// have to hardcode positions.
abstract final class ShellTab {
  static const home = 0;
  static const salon = 1;
  static const bookings = 2;
  static const alerts = 3;
  static const profile = 4;
}

// A request to switch MainShell's tab from outside its widget tree — set by
// the push-notification tap handler. MainShell listens and reacts, and ignores
// it entirely when it isn't mounted (e.g. the user is logged out), so a tap
// can never strand them on a screen that has no way back.
//
// Deliberately not "push the tab's screen as a route": MyServicesScreen has no
// back button of its own, because it was built to live inside the shell.
final ValueNotifier<int?> pendingShellTab = ValueNotifier<int?>(null);
