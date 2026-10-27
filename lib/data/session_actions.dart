import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_navigator.dart';
import '../providers/auth_providers.dart';
import '../providers/booking_providers.dart';
import '../providers/complaint_providers.dart';
import '../providers/customer_providers.dart';
import '../providers/favourites_providers.dart';
import '../providers/finance_providers.dart';
import '../providers/notification_providers.dart';
import '../providers/push_providers.dart';
import '../providers/realtime_providers.dart';
import '../providers/service_request_providers.dart';
import '../screens/otp_request_screen.dart';

Future<void> signOut(BuildContext context, {bool everywhere = false}) async {
  final container = ProviderScope.containerOf(context);
  final navigator = Navigator.of(context);

  await container
      .read(pushNotificationServiceProvider)
      .unregisterCurrentToken();
  final auth = container.read(authRepositoryProvider);
  if (everywhere) {
    await auth.revokeAllSessions();
    await container.read(apiClientProvider).clearTokens();
  } else {
    await auth.logout();
  }
  container.read(socketServiceProvider).disconnect();

  navigator.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const OtpRequestScreen()),
    (route) => false,
  );
  resetSessionState(container);
}

void resetSessionState(ProviderContainer container) {
  pendingShellTab.value = null;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    container.invalidate(authProvider);
    container.invalidate(myProfileProvider);
    container.invalidate(profilePhotoUrlProvider);
    container.invalidate(profileSetupProvider);
    container.invalidate(favouritesProvider);
    container.invalidate(activeSessionsProvider);
    container.invalidate(customerProductsProvider);
    container.invalidate(myComplaintsProvider);
    container.invalidate(complaintDetailProvider);
    container.invalidate(myNotificationsProvider);
    container.invalidate(unreadNotificationCountProvider);
    container.invalidate(myServiceRequestsProvider);
    container.invalidate(serviceRequestDetailProvider);
    container.invalidate(assignmentHistoryProvider);
    container.invalidate(activityLogProvider);
    container.invalidate(serviceVisitsProvider);
    container.invalidate(reopenHistoryProvider);
    container.invalidate(estimateForRequestProvider);
    container.invalidate(proformaForRequestProvider);
    container.invalidate(invoiceForRequestProvider);
    container.invalidate(paymentsForInvoiceProvider);
    container.invalidate(invoiceNotesProvider);
    container.invalidate(serviceRequestRealtimeProvider);
  });
}
