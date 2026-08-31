import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/errors/app_exception.dart';
import '../../data/services/google_auth_service.dart';
import 'core_providers.dart';

enum AuthStatus { checking, signedOut, signedIn }

class AuthState {
  const AuthState({required this.status, this.account, this.errorMessage});

  final AuthStatus status;
  final GoogleSignInAccount? account;
  final String? errorMessage;

  bool get isSignedIn => status == AuthStatus.signedIn && account != null;

  AuthState copyWith({
    AuthStatus? status,
    GoogleSignInAccount? account,
    bool clearAccount = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      account: clearAccount ? null : (account ?? this.account),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._service) : super(const AuthState(status: AuthStatus.checking)) {
    _restore();
  }

  final GoogleAuthService _service;

  Future<void> _restore() async {
    try {
      final account = await _service.restoreSession();
      state = account != null
          ? AuthState(status: AuthStatus.signedIn, account: account)
          : const AuthState(status: AuthStatus.signedOut);
    } catch (_) {
      state = const AuthState(status: AuthStatus.signedOut);
    }
  }

  Future<void> signIn() async {
    try {
      final account = await _service.signIn();
      state = AuthState(status: AuthStatus.signedIn, account: account);
    } on AppException catch (e) {
      state = state.copyWith(status: AuthStatus.signedOut, errorMessage: e.message, clearAccount: true);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.signedOut,
        errorMessage: 'فشل تسجيل الدخول إلى Google: $e',
        clearAccount: true,
      );
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    state = const AuthState(status: AuthStatus.signedOut);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(googleAuthServiceProvider));
});
