/// Build-time configuration.
///
/// No secrets live here. `googleServerClientId` (Web client) and
/// `googleIosClientId` (iOS client) are OAuth 2.0 client IDs from Google
/// Cloud Console - identifiers, not secrets - that google_sign_in needs on
/// Android and iOS respectively. Pass them at build/run time so they never
/// sit in source control:
///
///   flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxxx.apps.googleusercontent.com
///   flutter build apk --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxxx.apps.googleusercontent.com
///   flutter build ipa --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxxx.apps.googleusercontent.com --dart-define=GOOGLE_IOS_CLIENT_ID=yyyyy.apps.googleusercontent.com
///
/// See README.md for how to obtain these values.
class Env {
  Env._();

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  /// Only needed on iOS/macOS; unused (and safe to leave empty) on Android.
  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: '',
  );

  static bool get isConfigured => googleServerClientId.isNotEmpty;
}
