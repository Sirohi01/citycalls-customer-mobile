import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/otp_request_screen.dart';

void main() {
  runApp(const ProviderScope(child: CityCallsCustomerApp()));
}

class CityCallsCustomerApp extends StatelessWidget {
  const CityCallsCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CityCalls',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const OtpRequestScreen(),
    );
  }
}
