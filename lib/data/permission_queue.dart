// Android shows one runtime-permission dialog at a time, and the plugins
// (geolocator, firebase_messaging) don't queue behind each other — a second
// request made while a dialog is up is dropped or reported as denied. At
// startup the location and notification prompts used to race exactly like
// that, so the location one never showed until the user tapped "Use current
// location" later. Every runtime prompt goes through here, one after another.
abstract final class PermissionQueue {
  static Future<void> _tail = Future<void>.value();

  static Future<T> run<T>(Future<T> Function() request) {
    final result = _tail.then((_) => request());
    _tail = result.then((_) {}, onError: (_) {});
    return result;
  }
}
