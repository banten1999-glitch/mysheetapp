import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/connectivity_provider.dart';
import 'presentation/providers/ledger_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/screens/splash/splash_screen.dart';

class HasnawiLedgerApp extends ConsumerStatefulWidget {
  const HasnawiLedgerApp({super.key});

  @override
  ConsumerState<HasnawiLedgerApp> createState() => _HasnawiLedgerAppState();
}

class _HasnawiLedgerAppState extends ConsumerState<HasnawiLedgerApp> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    // Auto-sync: whenever connectivity flips to online (and the setting is
    // enabled and the user is signed in), attempt to flush the pending
    // queue. The repository's own in-flight guard makes this safe to fire
    // alongside a manual "sync now" tap.
    ref.listen(isOnlineProvider, (previous, next) {
      final wasOffline = previous?.value == false;
      final isNowOnline = next.value == true;
      final signedIn = ref.read(authProvider).isSignedIn;
      final autoSync = ref.read(settingsProvider).autoSync;
      if (wasOffline && isNowOnline && signedIn && autoSync) {
        ref.read(ledgerProvider.notifier).syncAll(interactive: false);
      }
    });

    return MaterialApp(
      title: settings.appName,
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const SplashScreen(),
    );
  }
}
