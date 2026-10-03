import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

/// Fraud Defense (reCAPTCHA Enterprise) site keys configured in Firebase App Check.
const String kIosRecaptchaSiteKey = '6LeDStwtAAAAACXAuGfNoeTRi7aB-mmlToO-QZcb';
const String kAndroidRecaptchaSiteKey = '6Lf2utgtAAAAAFsI-5cfYSkaAy2MXSl43RDzR2Ta';
const String kWebRecaptchaSiteKey = '6LcJmdgtAAAAAFI3-tcjsrtqt2EkMXVeaDaNtbos';

/// Activates Firebase App Check across iOS, Android, and Web using
/// Fraud Defense (reCAPTCHA Enterprise) in production and debug providers in development.
Future<void> initializeAppCheck() async {
  await FirebaseAppCheck.instance.activate(
    providerApple: kDebugMode
        ? const AppleDebugProvider()
        : const AppleReCaptchaProvider(kIosRecaptchaSiteKey),
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidReCaptchaProvider(kAndroidRecaptchaSiteKey),
    providerWeb: kDebugMode
        ? WebDebugProvider()
        : ReCaptchaEnterpriseProvider(kWebRecaptchaSiteKey),
  );
}
