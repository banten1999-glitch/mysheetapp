import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as gapis;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

import '../../core/config/env.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';

/// Wraps google_sign_in (v7 API) and hands out an authenticated http client
/// scoped to Sheets + Drive, ready for use with the `googleapis` package.
///
/// Session persistence (silent restore) is handled entirely by the native
/// Google Sign-In SDK - this app never stores access/refresh tokens itself.
class GoogleAuthService {
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      // iOS/macOS require their own OAuth client ID here; Android ignores
      // this and only needs serverClientId (see google_auth_service docs).
      clientId: Env.googleIosClientId.isNotEmpty ? Env.googleIosClientId : null,
      serverClientId: Env.isConfigured ? Env.googleServerClientId : null,
    );
    _initialized = true;
  }

  Stream<GoogleSignInAuthenticationEvent> get authenticationEvents =>
      GoogleSignIn.instance.authenticationEvents;

  /// Attempts to restore a previous session without showing any UI.
  Future<GoogleSignInAccount?> restoreSession() async {
    await _ensureInitialized();
    final future = GoogleSignIn.instance.attemptLightweightAuthentication();
    if (future == null) return null;
    try {
      return await future;
    } on GoogleSignInException {
      return null;
    }
  }

  /// Starts an interactive sign-in flow (must be triggered by a user tap).
  Future<GoogleSignInAccount> signIn() async {
    await _ensureInitialized();
    try {
      return await GoogleSignIn.instance.authenticate(
        scopeHint: AppConstants.googleScopes,
      );
    } on GoogleSignInException catch (e) {
      throw AuthException(_describe(e));
    }
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    await GoogleSignIn.instance.signOut();
  }

  /// Returns an authenticated http client for the Sheets/Drive APIs,
  /// prompting the user for authorization only if silent authorization is
  /// unavailable (e.g. first use, or scopes were revoked). Only call this
  /// from a user-triggered action (button tap), per google_sign_in's
  /// requirement that authorization prompts originate from user interaction.
  Future<gapis.AuthClient> getAuthorizedClient(
    GoogleSignInAccount account, {
    List<String> scopes = AppConstants.googleScopes,
  }) async {
    try {
      GoogleSignInClientAuthorization? authorization =
          await account.authorizationClient.authorizationForScopes(scopes);
      authorization ??= await account.authorizationClient.authorizeScopes(scopes);
      return authorization.authClient(scopes: scopes);
    } on GoogleSignInException catch (e) {
      throw AuthException(_describe(e));
    }
  }

  /// Like [getAuthorizedClient] but never prompts the user - returns null if
  /// the scopes aren't already silently authorized. Safe to call from
  /// background/non-interactive contexts (app startup, pull-to-refresh).
  Future<gapis.AuthClient?> getSilentAuthorizedClient(
    GoogleSignInAccount account, {
    List<String> scopes = AppConstants.googleScopes,
  }) async {
    try {
      final authorization = await account.authorizationClient.authorizationForScopes(scopes);
      if (authorization == null) return null;
      return authorization.authClient(scopes: scopes);
    } on GoogleSignInException {
      return null;
    }
  }

  String _describe(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.canceled:
        return 'تم إلغاء تسجيل الدخول.';
      case GoogleSignInExceptionCode.interrupted:
        return 'انقطعت عملية تسجيل الدخول. حاول مرة أخرى.';
      case GoogleSignInExceptionCode.clientConfigurationError:
        return 'إعداد OAuth غير صحيح. تحقق من SHA-1/SHA-256 و Client ID في Google Cloud Console.';
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'خطأ في إعدادات مزود تسجيل الدخول من Google.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'تعذّر عرض واجهة تسجيل الدخول حالياً.';
      // ignore: no_default_cases
      default:
        return 'فشل تسجيل الدخول إلى Google: ${e.description ?? e.code}';
    }
  }
}
