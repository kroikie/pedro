import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:firebase_admin_sdk/messaging.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';

Future<void> sendGameNotification({
  required FirebaseApp adminApp,
  required Firestore firestore,
  required List<String> recipientUids,
  required String title,
  required String body,
  required Map<String, String> data,
}) async {
  if (recipientUids.isEmpty) return;
  try {
    final messaging = adminApp.messaging();
    for (final uid in recipientUids) {
      final userDoc = await firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) continue;
      final userData = userDoc.data();
      final tokensMap =
          (userData?['fcmTokens'] as Map<String, dynamic>?) ?? {};
      final tokens = tokensMap.keys.toList();
      if (tokens.isEmpty) continue;

      final message = MulticastMessage(
        tokens: tokens,
        notification: Notification(title: title, body: body),
        data: data,
        android: AndroidConfig(
          priority: AndroidConfigPriority.high,
          notification: AndroidNotification(
            channelId: 'game_turns',
            sound: 'default',
          ),
        ),
        apns: ApnsConfig(
          payload: ApnsPayload(
            aps: Aps(
              sound: const ApsSoundName('default'),
              badge: 1,
            ),
          ),
        ),
      );

      final response = await messaging.sendEachForMulticast(message);
      for (var i = 0; i < response.responses.length; i++) {
        final res = response.responses[i];
        if (!res.success) {
          final errCode = res.error?.code;
          if (errCode == 'messaging/registration-token-not-registered' ||
              errCode == 'messaging/invalid-registration-token') {
            try {
              await firestore.collection('users').doc(uid).update({
                'fcmTokens.${tokens[i]}': FieldValue.delete,
              });
            } catch (_) {}
          }
        }
      }
    }
  } catch (e) {
    print('Error sending FCM notification: $e');
  }
}
