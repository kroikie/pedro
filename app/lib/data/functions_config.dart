import 'package:cloud_functions/cloud_functions.dart';
import 'emulator_config.dart';

/// The Google Cloud project number associated with deployed Cloud Functions.
const String defaultFunctionsProjectNumber = String.fromEnvironment(
  'FUNCTIONS_PROJECT_NUMBER',
  defaultValue: '260654198138',
);

/// The Google Cloud region where functions are deployed.
const String defaultFunctionsRegion = String.fromEnvironment(
  'FUNCTIONS_REGION',
  defaultValue: 'us-central1',
);

/// Resolves the Cloud Run URL for a Dart callable function.
///
/// Follows the format: `https://<function-name>-<project-number>.<region>.run.app`
String resolveFunctionUrl(
  String functionName, {
  String projectNumber = defaultFunctionsProjectNumber,
  String region = defaultFunctionsRegion,
}) {
  return 'https://$functionName-$projectNumber.$region.run.app';
}

/// Extension on [FirebaseFunctions] to route callable functions to the correct
/// endpoint whether running locally with the Firebase Emulator or in production
/// against Google Cloud Run.
extension PedroFunctionsExtension on FirebaseFunctions {
  /// Returns an [HttpsCallable] targeting either the local emulator (by name)
  /// or the production Cloud Run URL (by URL format).
  HttpsCallable callable(
    String functionName, {
    HttpsCallableOptions? options,
    bool? useEmulator,
    String projectNumber = defaultFunctionsProjectNumber,
    String region = defaultFunctionsRegion,
  }) {
    final bool isEmulator = useEmulator ?? shouldConnectToFirebaseEmulator();
    if (isEmulator) {
      return httpsCallable(functionName, options: options);
    }
    final url = resolveFunctionUrl(
      functionName,
      projectNumber: projectNumber,
      region: region,
    );
    return httpsCallableFromUrl(url, options: options);
  }
}
