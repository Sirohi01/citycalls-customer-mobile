import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main_shell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/service_request_providers.dart';

class BookingSuccessScreen extends ConsumerWidget {
  final String requestNumber;
  const BookingSuccessScreen({super.key, required this.requestNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          // Background soft gradient to mimic waves
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF16A34A).withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: 0,
            right: 0,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF16A34A).withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // --- Icon & Confetti ---
                          SizedBox(
                            width: 160,
                            height: 160,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Faint outer halo
                                Container(
                                  width: 130,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                                  ),
                                ),
                                // Main green circle
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16A34A),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.check, color: Colors.white, size: 50),
                                ),
                                // Confetti pieces (simplified via positioned icons/shapes)
                                Positioned(top: 20, left: 30, child: Transform.rotate(angle: -0.5, child: Container(width: 6, height: 16, color: const Color(0xFF16A34A)))),
                                Positioned(top: 10, right: 40, child: Transform.rotate(angle: 0.5, child: Container(width: 8, height: 20, color: const Color(0xFF16A34A)))),
                                Positioned(bottom: 20, left: 10, child: Transform.rotate(angle: 0.8, child: Container(width: 8, height: 18, color: const Color(0xFF16A34A)))),
                                Positioned(bottom: 40, right: 10, child: Transform.rotate(angle: -0.8, child: Container(width: 7, height: 16, color: const Color(0xFF16A34A)))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // --- Text ---
                          const Text(
                            'Booking Confirmed!',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black87),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your service request $requestNumber\nhas been created. We\'ll notify you once a\ntechnician is assigned.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54, fontSize: 15, height: 1.4),
                          ),
                          const SizedBox(height: 32),
                          
                          // --- Request ID Card ---
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                // Document Icon with check badge
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    const Icon(Icons.description_outlined, color: Color(0xFF16A34A), size: 36),
                                    Positioned(
                                      bottom: -4,
                                      right: -4,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF16A34A),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.check, color: Colors.white, size: 10),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Container(width: 1, height: 40, color: Colors.black12),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Request ID', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 2),
                                      Text(requestNumber, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black87)),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: requestNumber));
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request ID copied')));
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Icon(Icons.copy_outlined, color: Colors.black87, size: 22),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // --- Buttons ---
                          InkWell(
                            onTap: () {
                              ref.invalidate(myServiceRequestsProvider);
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const MainShell()),
                                (route) => false,
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F5132), // Darker green as per mockup
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(width: 20), // Balance the icon space
                                  Text('Go to My Services', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                                  Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: const Color(0xFF16A34A), width: 1.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: const Text('Book Another Service', style: TextStyle(color: Color(0xFF16A34A), fontSize: 15, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // --- Footer ---
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      const Icon(Icons.home, color: Color(0xFF16A34A), size: 20),
                      const SizedBox(height: 4),
                      const Text('We\'re here to keep your home running smoothly', style: TextStyle(color: Colors.black54, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
