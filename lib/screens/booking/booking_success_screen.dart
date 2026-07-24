import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../main_shell.dart';

// Per docs/rohit/05-customer-app-screen-list.md "Booking" — Booking Success.
class BookingSuccessScreen extends StatelessWidget {
  final String requestNumber;
  const BookingSuccessScreen({super.key, required this.requestNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(color: AppColors.black, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 24),
              const Text('Booking Confirmed!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Your service request $requestNumber has been created. We\'ll notify you once a technician is assigned.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.neutral500),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MainShell()),
                    (route) => false,
                  ),
                  child: const Text('Go to My Services'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
