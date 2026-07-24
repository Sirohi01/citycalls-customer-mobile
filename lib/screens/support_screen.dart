import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'my_complaints_screen.dart';

// Per docs/rohit/05-customer-app-screen-list.md "Support" — Contact Support /
// Raise Complaint, FAQ/Help. Raise Complaint is now a real ticket (see
// my_complaints_screen.dart / raise_complaint_screen.dart, backed by
// citycalls-api's src/modules/complaints); this screen still offers direct
// contact as an alternative, not a replacement.
// NOTE: the contact details below are placeholders — swap in the real
// support phone/email/WhatsApp number before shipping.
const _supportPhone = '+91-00000-00000';
const _supportEmail = 'support@citycalls.example';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const _faqs = [
    (
      'How do I book a service?',
      'Go to Home > Book a Service, pick your appliance and category, choose a service, confirm your area is covered, then follow the steps to select your appliance, address, describe the issue, and pick a time slot.',
    ),
    (
      'How do I know when a technician is assigned?',
      'Open the request from My Services — its status updates automatically as it moves from Request Received to Technician Assigned, On The Way, and so on.',
    ),
    (
      'Can I reschedule or cancel a booking?',
      'Yes — open the request from My Services and use the Reschedule or Cancel Request button. You\'ll be asked for a reason.',
    ),
    (
      'How do estimates and payments work?',
      'If the technician finds additional work is needed, you\'ll get an estimate to review and approve or reject from the request\'s detail screen. Once the job is done, you can view and pay the invoice from the same screen.',
    ),
    (
      'The issue came back after the technician left — what do I do?',
      'Open the completed request from My Services\' History tab and use "Reopen Request" — our team will follow up without needing a fresh booking.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Help & Support'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyComplaintsScreen())),
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.forum_outlined, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Raise a Complaint', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                        Text('Track your complaints and their responses', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
            ),
          ),
          const Text('Contact Us', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _ContactTile(icon: Icons.call_outlined, label: 'Call Support', value: _supportPhone),
          _ContactTile(icon: Icons.mail_outline, label: 'Email Support', value: _supportEmail),
          const SizedBox(height: 28),
          const Text('Frequently Asked Questions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ..._faqs.map((faq) => ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(faq.$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                childrenPadding: const EdgeInsets.only(bottom: 12),
                expandedAlignment: Alignment.centerLeft,
                children: [Text(faq.$2, style: const TextStyle(color: AppColors.neutral500, height: 1.4))],
              )),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ContactTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.neutral100, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.black),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.neutral500, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
