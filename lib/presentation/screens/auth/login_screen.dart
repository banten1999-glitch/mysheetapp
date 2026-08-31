import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/primary_button.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final appName = ref.watch(settingsProvider).appName;
    final isSigningIn = auth.status == AuthStatus.checking;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_rounded, size: 72, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 20),
              Text(
                appName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'سجّل الدخول بحساب Google لبدء تسجيل العمليات مباشرة في Google Sheets وGoogle Drive.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (!Env.isConfigured)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'لم يتم ضبط GOOGLE_SERVER_CLIENT_ID عند بناء التطبيق. راجع README.md.',
                    style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (auth.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    auth.errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              PrimaryButton(
                label: 'تسجيل الدخول بحساب Google',
                icon: Icons.login,
                isLoading: isSigningIn,
                onPressed: Env.isConfigured
                    ? () async {
                        ref.read(authProvider.notifier).clearError();
                        await ref.read(authProvider.notifier).signIn();
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
