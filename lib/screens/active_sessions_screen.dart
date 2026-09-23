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
  ConsumerState<ActiveSessionsScreen> createState() => _ActiveSessionsScreenState();
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
          const SnackBar(content: Text("Couldn't sign that device out. Please try again.")),
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign out everywhere')),
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
        const SnackBar(content: Text("Couldn't sign out everywhere. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(activeSessionsProvider);

    return Scaffold(
      backgroundColor: AppColors.neutral100,
      appBar: AppBar(title: const Text('Signed-in Devices'), centerTitle: false),
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
                  label: Text(_revokingAll ? 'Signing out...' : 'Sign out everywhere'),
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
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF16A34A))),
        error: (err, _) => Center(
          child: AppErrorView(error: err, onRetry: () => ref.invalidate(activeSessionsProvider)),
        ),
      ),
    );
  }

  Widget _sessionCard(AuthSession session) {
    final busy = _revoking == session.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.phone_iphone_rounded, color: AppColors.neutral500, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.device?.isNotEmpty == true ? session.device! : 'Unknown device',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (session.ipAddress != null) session.ipAddress!,
                    if (session.createdAt != null) 'since ${_formatDate(session.createdAt!)}',
                  ].join(' · '),
                  style: const TextStyle(fontSize: 11.5, color: AppColors.neutral500),
                ),
              ],
            ),
          ),
          busy
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
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
