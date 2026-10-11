import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_models.dart';
import '../providers/auth_providers.dart';
import '../providers/push_providers.dart';
import '../providers/realtime_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/state_views.dart';
import 'otp_request_screen.dart';

// GET /auth/sessions + DELETE /auth/sessions/:id — self-scoped, so a customer
// can see and end their own logins. Worth surfacing now that refresh tokens
// are actually stored on the device (api_client.dart): a session survives
// long past the access token, so "sign out everywhere" is the only way to cut
// off a phone the user no longer has.
class ActiveSessionsScreen extends ConsumerStatefulWidget {
  const ActiveSessionsScreen({super.key});

  @override
  ConsumerState<ActiveSessionsScreen> createState() =>
      _ActiveSessionsScreenState();
}

class _ActiveSessionsScreenState extends ConsumerState<ActiveSessionsScreen> {
  String? _revoking;
  bool _revokingAll = false;

  Future<void> _revoke(AuthSession session) async {
    setState(() => _revoking = session.id);
    try {
      await ref.read(authRepositoryProvider).revokeSession(session.id);
      ref.invalidate(activeSessionsProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text("Couldn't sign that device out. Please try again.")),
        );
      }
    } finally {
      if (mounted) setState(() => _revoking = null);
    }
  }

  Future<void> _revokeAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out everywhere?'),
        content: const Text(
          'This ends every active login, including this device. You will need to sign in again.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign out everywhere')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _revokingAll = true);
    try {
      await ref.read(authRepositoryProvider).revokeAllSessions();
      // This device's session is gone too, so tear down the same things a
      // normal logout does rather than leaving a live socket and a
      // registered FCM token behind.
      await ref.read(pushNotificationServiceProvider).unregisterCurrentToken();
      await ref.read(apiClientProvider).clearTokens();
      ref.read(socketServiceProvider).disconnect();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OtpRequestScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _revokingAll = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Couldn't sign out everywhere. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(activeSessionsProvider);

    return Scaffold(
      appBar:
          AppBar(title: const Text('Signed-in Devices'), centerTitle: false),
      body: sessions.when(
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyView(
              icon: Icons.devices_outlined,
              title: 'No other devices',
              subtitle: 'This is the only device signed in to your account.',
            );
          }
          return RefreshIndicator(
            color: const Color(0xFF16A34A),
            onRefresh: () async => ref.invalidate(activeSessionsProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final session in items) _sessionCard(session),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _revokingAll ? null : _revokeAll,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text(
                      _revokingAll ? 'Signing out...' : 'Sign out everywhere'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF16A34A))),
        error: (err, _) => Center(
          child: AppErrorView(
              error: err,
              onRetry: () => ref.invalidate(activeSessionsProvider)),
        ),
      ),
    );
  }

  Widget _sessionCard(AuthSession session) {
    final busy = _revoking == session.id;
    final deviceInfo = _friendlyDeviceInfo(session.device);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(deviceInfo.icon, color: deviceInfo.color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deviceInfo.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (deviceInfo.detail != null) deviceInfo.detail!,
                    if (session.ipAddress != null) session.ipAddress!,
                    if (session.createdAt != null)
                      'since ${_formatDate(session.createdAt!)}',
                  ].join(' · '),
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.neutral500),
                ),
              ],
            ),
          ),
          busy
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : TextButton(
                  onPressed: _revoking != null ? null : () => _revoke(session),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Sign out'),
                ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _DeviceInfo {
  final String name;
  final String? detail;
  final IconData icon;
  final Color color;

  const _DeviceInfo({
    required this.name,
    this.detail,
    required this.icon,
    required this.color,
  });
}

_DeviceInfo _friendlyDeviceInfo(String? rawDevice) {
  final raw = rawDevice?.trim();
  if (raw == null || raw.isEmpty) {
    return const _DeviceInfo(
      name: 'Unknown device',
      icon: Icons.devices_other_rounded,
      color: AppColors.neutral500,
    );
  }

  final lower = raw.toLowerCase();
  final isDartClient = lower.startsWith('dart/');
  final isAppleModelCode =
      RegExp(r'^i(phone|pad)\d+,\d+$', caseSensitive: false).hasMatch(raw);
  final isAndroid = lower.contains('android');
  final isIos = lower.contains('iphone') ||
      lower.contains('ipad') ||
      lower.contains('ios');
  final isWindows = lower.contains('windows');
  final isMac = lower.contains('mac os') || lower.contains('macintosh');
  final isLinux = lower.contains('linux') && !isAndroid;
  final isChrome = lower.contains('chrome') || lower.contains('crios');
  final isSafari = lower.contains('safari') && !isChrome;
  final isFirefox = lower.contains('firefox');
  final isEdge = lower.contains('edg/');

  if (isDartClient) {
    return const _DeviceInfo(
      name: 'CityCalls Mobile App',
      detail: 'This mobile device',
      icon: Icons.phone_android_rounded,
      color: Color(0xFF16A34A),
    );
  }

  if (isAppleModelCode) {
    return _DeviceInfo(
      name: raw,
      icon: lower.startsWith('ipad')
          ? Icons.tablet_mac_rounded
          : Icons.phone_iphone_rounded,
      color: const Color(0xFF2563EB),
    );
  }

  if (isAndroid) {
    return _DeviceInfo(
      name: 'Android device',
      detail: _browserName(isChrome, isSafari, isFirefox, isEdge),
      icon: Icons.phone_android_rounded,
      color: const Color(0xFF16A34A),
    );
  }
  if (isIos) {
    return _DeviceInfo(
      name: lower.contains('ipad') ? 'iPad' : 'iPhone',
      detail: _browserName(isChrome, isSafari, isFirefox, isEdge),
      icon: Icons.phone_iphone_rounded,
      color: const Color(0xFF2563EB),
    );
  }
  if (isWindows || isMac || isLinux) {
    return _DeviceInfo(
      name: isWindows
          ? 'Windows computer'
          : isMac
              ? 'Mac'
              : 'Linux computer',
      detail: _browserName(isChrome, isSafari, isFirefox, isEdge),
      icon: Icons.laptop_mac_rounded,
      color: const Color(0xFF7C3AED),
    );
  }

  return _DeviceInfo(
    name: raw.length > 36 ? '${raw.substring(0, 33)}...' : raw,
    icon: Icons.devices_other_rounded,
    color: AppColors.neutral500,
  );
}

String? _browserName(bool chrome, bool safari, bool firefox, bool edge) {
  if (edge) return 'Microsoft Edge';
  if (firefox) return 'Firefox';
  if (chrome) return 'Chrome';
  if (safari) return 'Safari';
  return null;
}
