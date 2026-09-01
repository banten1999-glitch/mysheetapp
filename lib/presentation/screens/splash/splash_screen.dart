import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../providers/settings_provider.dart';
import 'auth_gate.dart';

/// Branded opening sequence: the logo fades and scales in over a dark
/// gradient, a halo pulses behind it, the wordmark rises in, then the whole
/// thing cross-fades into the app. Total ~2.4s.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  late final AnimationController _haloController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  // Logo: fade in, then settle from slightly oversized to natural size.
  late final Animation<double> _logoOpacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.05, 0.42, curve: Curves.easeOut),
  );
  late final Animation<double> _logoScale = Tween(begin: 0.72, end: 1.0).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.05, 0.55, curve: Curves.easeOutBack),
    ),
  );

  // Wordmark rises a little after the logo lands.
  late final Animation<double> _textOpacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.38, 0.68, curve: Curves.easeOut),
  );
  late final Animation<Offset> _textSlide =
      Tween(begin: const Offset(0, 0.5), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.38, 0.72, curve: Curves.easeOutCubic),
        ),
      );

  // Everything eases away at the end so the hand-off isn't an abrupt cut.
  late final Animation<double> _exitOpacity = Tween(begin: 1.0, end: 0.0)
      .animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.88, 1.0, curve: Curves.easeIn),
        ),
      );

  bool _done = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _controller.forward().whenComplete(() {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _haloController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Warm the settings up behind the splash so the first real frame after
    // the hand-off already has the user's theme and configuration.
    final appName = ref.watch(settingsProvider).appName;

    if (_done) return const AuthGate();

    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      body: AnimatedBuilder(
        animation: Listenable.merge([_controller, _haloController]),
        builder: (context, _) {
          return Opacity(
            opacity: _exitOpacity.value,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: AppColors.splashGradient,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _Halo(progress: _haloController.value),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: const _SplashLogo(),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Opacity(
                        opacity: _textOpacity.value,
                        child: FractionalTranslation(
                          translation: _textSlide.value,
                          child: Column(
                            children: [
                              Text(
                                appName,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'إدارة العمليات المالية',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 14,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 56,
                    child: Opacity(
                      opacity: _textOpacity.value * 0.9,
                      child: SizedBox(
                        width: 120,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            minHeight: 3,
                            backgroundColor: Colors.white.withValues(alpha: 0.12),
                            valueColor: const AlwaysStoppedAnimation(
                              AppColors.cyan,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Logo plate - a soft white rounded square so the artwork (which has a
/// white background) sits naturally on the dark gradient.
class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      height: 148,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(38),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.35),
            blurRadius: 48,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stack) => const FittedBox(
          child: Text(
            '<MS>',
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w900,
              color: AppColors.navy,
              letterSpacing: -2,
            ),
          ),
        ),
      ),
    );
  }
}

/// Slow breathing glow behind the logo.
class _Halo extends StatelessWidget {
  const _Halo({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final scale = 0.9 + (progress * 0.22);
    return IgnorePointer(
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.cyan.withValues(alpha: 0.20),
                AppColors.violet.withValues(alpha: 0.10),
                Colors.transparent,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
