import 'package:flutter_test/flutter_test.dart';
import 'package:pedro/data/app_check_config.dart';

void main() {
  group('App Check Configuration', () {
    test('Fraud Defense / reCAPTCHA Enterprise site keys are configured for all platforms', () {
      expect(kIosRecaptchaSiteKey, isNotEmpty);
      expect(kAndroidRecaptchaSiteKey, isNotEmpty);
      expect(kWebRecaptchaSiteKey, isNotEmpty);

      expect(kIosRecaptchaSiteKey, '6LeDStwtAAAAACXAuGfNoeTRi7aB-mmlToO-QZcb');
      expect(kAndroidRecaptchaSiteKey, '6Lf2utgtAAAAAFsI-5cfYSkaAy2MXSl43RDzR2Ta');
      expect(kWebRecaptchaSiteKey, '6LcJmdgtAAAAAFI3-tcjsrtqt2EkMXVeaDaNtbos');
    });
  });
}
