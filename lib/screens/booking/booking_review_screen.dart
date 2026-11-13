import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/booking_models.dart';
import '../../providers/booking_providers.dart';
import '../../providers/customer_providers.dart';
import '../../providers/service_request_providers.dart';
import 'booking_success_screen.dart';

// Per docs/rohit/05-customer-app-screen-list.md "Booking" — Booking Review & Confirm.
class BookingReviewScreen extends ConsumerStatefulWidget {
  final BookingDraft draft;
  const BookingReviewScreen({super.key, required this.draft});

  @override
  ConsumerState<BookingReviewScreen> createState() =>
      _BookingReviewScreenState();
}

class _BookingReviewScreenState extends ConsumerState<BookingReviewScreen> {
  Map<String, dynamic>? _quote;
  bool _pricingLoading = true;
  int _quoteVersion = 0;
  late BookingDraft _draft;
  Future<void> _loadQuote() async {
    final version = ++_quoteVersion;
    setState(() {
      _pricingLoading = true;
      _quote = null;
      _error = null;
    });
    try {
      final quote = await ref.read(bookingRepositoryProvider).quote(_draft);
      if (mounted && version == _quoteVersion) setState(() => _quote = quote);
    } catch (e) {
      if (mounted && version == _quoteVersion) {
        setState(() => _error =
            'Could not confirm the latest price. Go back and try again. $e');
      }
    } finally {
      if (mounted && version == _quoteVersion) {
        setState(() => _pricingLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _draft = widget.draft;
    _loadQuote();
  }

  bool _submitting = false;
  String? _error;

  Future<void> _confirm() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final customerId = (await ref.read(myProfileProvider.future)).id;
      final result = await ref
          .read(bookingRepositoryProvider)
          .createServiceRequest(_draft, customerId,
              expectedTotal: (_quote!['total'] as num).toDouble());
      ref.invalidate(myServiceRequestsProvider);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (_) => BookingSuccessScreen(
                requestNumber: result['number'] as String)),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to submit your request: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    final address = draft.address!;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: Stack(
        children: [
          // Background Gradient matching the UI
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 350,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE8F6EC),
                    Color(0xFFF2F8F3),
                    Color(0xFFF6F7F9),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Custom Header ---
                Padding(
                  padding: const EdgeInsets.only(
                      top: 16, left: 20, right: 20, bottom: 8),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back,
                              color: Color(0xFF16A34A), size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text('Review & Confirm',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                    ],
                  ),
                ),

                // --- Title and Progress ---
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Review your booking',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87)),
                          RichText(
                              text: TextSpan(children: [
                            TextSpan(
                                text: 'Step ${widget.draft.stepNumber(5)} ',
                                style: TextStyle(
                                    color: Color(0xFF16A34A),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                            TextSpan(
                                text: 'of ${widget.draft.totalSteps}',
                                style: TextStyle(
                                    color: Color(0xFF16A34A),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ]))
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 1.0,
                          minHeight: 5,
                          backgroundColor: Colors.grey.shade200,
                          valueColor:
                              const AlwaysStoppedAnimation(Color(0xFF16A34A)),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView(
                            children: [
                              _section(context, Icons.build_outlined, 'Service',
                                  draft.serviceName),
                              if (draft.pricingMode == 'HOURLY') ...[
                                ListTile(
                                    title: const Text('Booked hours'),
                                    trailing: DropdownButton<int>(
                                        value: draft.hours,
                                        items: List.generate(
                                            16,
                                            (i) => DropdownMenuItem(
                                                value: i + 1,
                                                child: Text('${i + 1} hr'))),
                                        onChanged: _submitting
                                            ? null
                                            : (v) {
                                                setState(() => _draft =
                                                    draft.copyWith(hours: v));
                                                _loadQuote();
                                              })),
                                ListTile(
                                    title: const Text('Helpers'),
                                    trailing: DropdownButton<int>(
                                        value: draft.helpers,
                                        items: List.generate(
                                            4,
                                            (i) => DropdownMenuItem(
                                                value: i + 1,
                                                child: Text('${i + 1}'))),
                                        onChanged: _submitting
                                            ? null
                                            : (v) {
                                                setState(() => _draft =
                                                    draft.copyWith(helpers: v));
                                                _loadQuote();
                                              })),
                                _section(context, Icons.schedule, 'Hourly plan',
                                    '₹${((_quote?["unitPrice"] as num?)?.toDouble() ?? draft.unitPrice).toStringAsFixed(2)} × ${draft.hours} hours × ${draft.helpers} helpers'),
                              ],
                              if (draft.visitingCharge > 0)
                                _section(context, Icons.home, 'Visiting charge',
                                    '₹${draft.visitingCharge.toStringAsFixed(2)}'),
                              if (_quote?['taxBreakup'] is Map)
                                _section(
                                    context,
                                    Icons.receipt_outlined,
                                    'GST included in total',
                                    '₹${((_quote!['taxBreakup'] as Map).values.whereType<num>().fold<double>(0, (sum, value) => sum + value.toDouble())).toStringAsFixed(2)}'),
                              _section(
                                  context,
                                  Icons.currency_rupee,
                                  draft.pricingMode == 'ESTIMATE'
                                      ? 'Visit / inspection amount'
                                      : 'Agreed booking total',
                                  _pricingLoading
                                      ? 'Calculating…'
                                      : _quote == null
                                          ? 'Price unavailable'
                                          : '₹${(_quote!['total'] as num).toStringAsFixed(2)}'),
                              if (draft.pricingMode == 'ESTIMATE')
                                const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Text(
                                        'Repair charges will be shared after inspection and need your approval.')),
                              if (draft.pricingMode == 'HOURLY')
                                const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Text(
                                        'This price covers the booked hours and helpers. Extra work needs a separate approved estimate.')),

                              _section(
                                context,
                                Icons.location_on,
                                'Address',
                                [
                                  address.label,
                                  address.line1,
                                  address.line2,
                                  address.landmark,
                                  address.city,
                                  address.state,
                                  address.pinCode
                                ]
                                    .where((s) => s != null && s.isNotEmpty)
                                    .join(', '),
                              ),
                              if (draft.symptoms.isNotEmpty)
                                _section(
                                    context,
                                    Icons.report_gmailerrorred_outlined,
                                    'Symptoms',
                                    draft.symptoms.join(', ')),
                              if (draft.notes != null &&
                                  draft.notes!.isNotEmpty)
                                _section(context, Icons.notes_outlined, 'Notes',
                                    draft.notes!),
                              if (draft.imageUrls.isNotEmpty)
                                _section(
                                    context,
                                    Icons.photo_library_outlined,
                                    'Photos attached',
                                    '${draft.imageUrls.length} photo(s)'),
                              _section(
                                  context,
                                  Icons.calendar_today_outlined,
                                  'Preferred date',
                                  draft.scheduledDate == null
                                      ? '—'
                                      : '${draft.scheduledDate!.day}/${draft.scheduledDate!.month}/${draft.scheduledDate!.year}'),
                              _section(context, Icons.schedule,
                                  'Preferred time', draft.scheduledSlot ?? '—'),

                              const SizedBox(height: 12),
                              // Almost there banner
                              Container(
                                margin: const EdgeInsets.only(bottom: 20),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF16A34A),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                          Icons.check_circle_outline,
                                          color: Colors.white,
                                          size: 28),
                                    ),
                                    const SizedBox(width: 16),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Almost there!',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Colors.black87)),
                                          SizedBox(height: 4),
                                          Text(
                                              'Please review all the details carefully before confirming your booking.',
                                              style: TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 13,
                                                  height: 1.3)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_error != null)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(_error!,
                                  style: const TextStyle(color: Colors.red))),

                        // Confirm Button
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 20),
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed:
                                _submitting || _pricingLoading || _quote == null
                                    ? null
                                    : _confirm,
                            icon: _submitting
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.check_circle_outline,
                                    size: 20),
                            label: Text(
                                _submitting
                                    ? 'Submitting...'
                                    : 'Confirm Booking',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(
      BuildContext context, IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF16A34A)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 18),
        ],
      ),
    );
  }
}
