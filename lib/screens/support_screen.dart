import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/catalog_models.dart';
import '../providers/catalog_providers.dart';
import '../widgets/ui_kit.dart';
import 'my_complaints_screen.dart';

// Help & Support: raise/track complaints, contact CityCalls (call, WhatsApp,
// email — numbers come from the admin-managed social links on the live API,
// with built-in fallbacks), and FAQs.
class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  static const _faqs = [
    (
      'How do I book a service?',
      'Go to Home > Book a Service, pick your appliance and category, choose a service, confirm your area is covered, then follow the steps to select your appliance, address, describe the issue, and pick a time slot.',
    ),
    (
      'How do I know when a technician is assigned?',
      'Open the booking from My Bookings — its status updates automatically as it moves from Request Received to Technician Assigned, On The Way, and so on.',
    ),
    (
      'Can I reschedule or cancel a booking?',
      'Yes — open the booking from My Bookings and use the Reschedule or Cancel Request button. You\'ll be asked for a reason.',
    ),
    (
      'How do estimates and payments work?',
      'If the technician finds additional work is needed, you\'ll get an estimate to review and approve or reject from the request\'s detail screen. Once the job is done, you can view and pay the invoice from the same screen.',
    ),
    (
      'Where can I see what the technician actually did?',
      'Open the booking from My Bookings and tap "View Work Details" — it shows the diagnosis, any parts fitted with their prices, the technician\'s work notes, and before/after photos from the visit.',
    ),
    (
      'The issue came back after the technician left — what do I do?',
      'Open the completed booking from My Bookings\' History tab and use "Reopen Request" — our team will follow up without needing a fresh booking. The request\'s detail screen then shows whether it was approved or rejected.',
    ),
    (
      'How do I sign out of a phone I no longer use?',
      'Go to Profile > Signed-in Devices. You can end any single device\'s session there, or sign out everywhere at once.',
    ),
  ];

  Future<void> _launch(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this on your phone.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contact = ref.watch(supportContactProvider).valueOrNull ??
        SupportContact.fallback;

    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          // Complaints
          Material(
            color: kInk,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const MyComplaintsScreen())),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.forum_rounded,
                          color: Color(0xFF8BD450)),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Raise a complaint',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontSize: 15)),
                          SizedBox(height: 2),
                          Text('Track your complaints and our replies',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const UiSectionLabel('Contact us'),
          UiCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _ContactTile(
                  icon: Icons.call_rounded,
                  color: kGreen,
                  label: 'Call us',
                  value: contact.displayCallNumber,
                  onTap: () => _launch(
                      context, Uri(scheme: 'tel', path: contact.callNumber)),
                ),
                const Divider(height: 1, indent: 66),
                _ContactTile(
                  icon: Icons.chat_rounded,
                  color: const Color(0xFF25D366),
                  label: 'Chat on WhatsApp',
                  value: 'Usually replies within minutes',
                  onTap: () => _launch(
                      context,
                      Uri.https('wa.me', '/${contact.whatsappNumber}',
                          {'text': contact.whatsappMessage})),
                ),
                const Divider(height: 1, indent: 66),
                _ContactTile(
                  icon: Icons.mail_rounded,
                  color: const Color(0xFF2563EB),
                  label: 'Email us',
                  value: contact.email,
                  onTap: () => _launch(
                      context,
                      Uri(
                          scheme: 'mailto',
                          path: contact.email,
                          queryParameters: {'subject': 'Help with CityCalls'})),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const UiSectionLabel('Frequently asked questions'),
          UiCard(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                for (var i = 0; i < _faqs.length; i++)
                  Column(
                    children: [
                      Theme(
                        // No divider lines from ExpansionTile itself.
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          iconColor: kInk,
                          collapsedIconColor: kFaint,
                          title: Text(_faqs[i].$1,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                  color: kInk)),
                          childrenPadding: const EdgeInsets.only(bottom: 14),
                          expandedAlignment: Alignment.centerLeft,
                          children: [
                            Text(_faqs[i].$2,
                                style: const TextStyle(
                                    color: kMuted, height: 1.45, fontSize: 13))
                          ],
                        ),
                      ),
                      if (i != _faqs.length - 1) const Divider(height: 1),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final VoidCallback onTap;
  const _ContactTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            UiIconTile(icon: icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                          color: kInk)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(fontSize: 12.5, color: kMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: kFaint),
          ],
        ),
      ),
    );
  }
}
