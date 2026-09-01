import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_background.dart';
import '../../widgets/ms_logo.dart';
import '../../widgets/primary_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  bool _signingIn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _signingIn = true);
    ref.read(authProvider.notifier).clearError();
    await ref.read(authProvider.notifier).signIn();
    if (mounted) setState(() => _signingIn = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final appName = ref.watch(settingsProvider).appName;

    final fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    final slide = Tween(
      begin: const Offset(0, 0.16),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slide,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(34),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.blue.withValues(alpha: 0.25),
                            blurRadius: 40,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: const MsLogo(size: 96),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      appName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'سجّل الدخول بحساب Google لتسجيل عملياتك مباشرة في\nGoogle Sheets وGoogle Drive.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 38),
                    if (!Env.isConfigured)
                      _Notice(
                        text:
                            'لم يتم ضبط GOOGLE_SERVER_CLIENT_ID عند بناء التطبيق. راجع README.md.',
                        color: AppColors.danger,
                      ),
                    if (auth.errorMessage != null)
                      _Notice(
                        text: auth.errorMessage!,
                        color: AppColors.danger,
                      ),
                    PrimaryButton(
                      label: 'تسجيل الدخول بحساب Google',
                      icon: Icons.login_rounded,
                      isLoading: _signingIn,
                      onPressed: Env.isConfigured ? _signIn : null,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'اتصال آمن عبر OAuth 2.0',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: color, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 13, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
