import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_background.dart';
import '../../widgets/ms_logo.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';

/// Routes to the home or login screen once the silent sign-in restore has
/// resolved. Shown after the splash animation completes.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final appName = ref.watch(settingsProvider).appName;

    if (authState.status == AuthStatus.checking) {
      return AppBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MsLogo(size: 92),
                const SizedBox(height: 20),
                Text(appName, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 28),
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.6),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: authState.isSignedIn
          ? const HomeScreen(key: ValueKey('home'))
          : const LoginScreen(key: ValueKey('login')),
    );
  }
}
