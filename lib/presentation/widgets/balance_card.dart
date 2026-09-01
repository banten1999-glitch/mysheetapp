import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Only DateFormat - intl also exports a TextDirection that would shadow
// the one from Flutter.
import 'package:intl/intl.dart' show DateFormat;

import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../providers/balance_provider.dart';
import '../providers/core_providers.dart';
import '../providers/settings_provider.dart';
import 'app_snackbar.dart';

/// Headline card: remaining balance in EGP with its USD equivalent beneath,
/// plus a tap-to-refresh exchange rate.
class BalanceCard extends ConsumerStatefulWidget {
  const BalanceCard({super.key});

  @override
  ConsumerState<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends ConsumerState<BalanceCard> {
  bool _refreshingRate = false;

  Future<void> _refreshRate() async {
    setState(() => _refreshingRate = true);
    try {
      final rate = await ref.read(exchangeRateServiceProvider).fetchUsdToEgp();
      await ref.read(settingsProvider.notifier).update(
            (s) => s.copyWith(usdRate: rate, usdRateUpdatedAt: DateTime.now()),
          );
      if (mounted) {
        AppSnackbar.success(
          context,
          'تم تحديث سعر الصرف: ${AppFormatters.amount(rate)} جنيه للدولار',
        );
      }
    } on AppException catch (e) {
      if (mounted) AppSnackbar.error(context, e.message);
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'تعذّر تحديث سعر الصرف: $e');
    } finally {
      if (mounted) setState(() => _refreshingRate = false);
    }
  }

  Future<void> _editRateManually() async {
    final settings = ref.read(settingsProvider);
    final controller = TextEditingController(
      text: settings.hasUsdRate ? settings.usdRate.toString() : '',
    );

    final value = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('سعر الصرف يدوياً'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'كم جنيهاً مصرياً يساوي الدولار الواحد؟ أدخل السعر من البنك '
              'الذي تعتمده.',
              style: TextStyle(height: 1.5, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textDirection: TextDirection.ltr,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                suffixText: 'جنيه / دولار',
                hintText: '48.50',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.trim());
              Navigator.of(dialogContext).pop(parsed);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (value != null && value > 0) {
      await ref.read(settingsProvider.notifier).update(
            (s) => s.copyWith(usdRate: value, usdRateUpdatedAt: DateTime.now()),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final totalsAsync = ref.watch(sheetTotalsProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.navy, Color(0xFF12306B), AppColors.navyDeep],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: totalsAsync.when(
        loading: () => const _CardShell(child: _LoadingBody()),
        error: (error, _) => _CardShell(
          child: _MessageBody(
            icon: Icons.error_outline_rounded,
            text: error is AppException ? error.message : 'تعذّرت قراءة الرصيد.',
            onRetry: () => ref.invalidate(sheetTotalsProvider),
          ),
        ),
        data: (totals) {
          if (totals == null) {
            return const _CardShell(
              child: _MessageBody(
                icon: Icons.cloud_off_rounded,
                text: 'الرصيد غير متاح — تحقق من الاتصال وربط الشيت.',
              ),
            );
          }
          return _BalanceBody(
            remaining: totals.remaining,
            credit: totals.credit,
            debit: totals.debit,
            currency: settings.currency,
            usdRate: settings.usdRate,
            rateUpdatedAt: settings.usdRateUpdatedAt,
            refreshing: _refreshingRate,
            onRefreshRate: _refreshRate,
            onEditRate: _editRateManually,
            onRefreshBalance: () => ref.invalidate(sheetTotalsProvider),
          );
        },
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(height: 132, child: child);
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          valueColor: AlwaysStoppedAnimation(AppColors.cyan),
        ),
      ),
    );
  }
}

class _MessageBody extends StatelessWidget {
  const _MessageBody({required this.icon, required this.text, this.onRetry});

  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 26),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'إعادة المحاولة',
                style: TextStyle(color: AppColors.cyan, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

class _BalanceBody extends StatelessWidget {
  const _BalanceBody({
    required this.remaining,
    required this.credit,
    required this.debit,
    required this.currency,
    required this.usdRate,
    required this.rateUpdatedAt,
    required this.refreshing,
    required this.onRefreshRate,
    required this.onEditRate,
    required this.onRefreshBalance,
  });

  final double remaining;
  final double credit;
  final double debit;
  final String currency;
  final double usdRate;
  final DateTime? rateUpdatedAt;
  final bool refreshing;
  final VoidCallback onRefreshRate;
  final VoidCallback onEditRate;
  final VoidCallback onRefreshBalance;

  @override
  Widget build(BuildContext context) {
    final isNegative = remaining < 0;
    final valueColor = isNegative
        ? const Color(0xFFFF9E9E)
        : const Color(0xFF5EE9B5);
    final hasRate = usdRate > 0;
    final usd = hasRate ? remaining / usdRate : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              'الباقي',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            _MiniAction(icon: Icons.refresh_rounded, onTap: onRefreshBalance),
          ],
        ),
        const SizedBox(height: 6),

        // EGP balance
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  AppFormatters.amount(remaining),
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              currency,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        // USD equivalent
        const SizedBox(height: 4),
        InkWell(
          onTap: onEditRate,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(
                  hasRate
                      ? '≈ ${AppFormatters.amount(usd!)} USD'
                      : 'اضغط لتحديد سعر الصرف',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: hasRate ? 0.9 : 0.65),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                if (hasRate)
                  Text(
                    '(${AppFormatters.amount(usdRate)} ج/\$)',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11.5,
                    ),
                  ),
                const Spacer(),
                if (refreshing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.cyan),
                    ),
                  )
                else
                  _MiniAction(
                    icon: Icons.sync_rounded,
                    onTap: onRefreshRate,
                    tint: AppColors.cyan,
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),
        Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _Stat(
                label: 'إجمالي المستلم',
                value: AppFormatters.amount(credit),
                color: const Color(0xFF5EE9B5),
              ),
            ),
            Container(
              width: 1,
              height: 26,
              color: Colors.white.withValues(alpha: 0.12),
            ),
            Expanded(
              child: _Stat(
                label: 'إجمالي المدفوع',
                value: AppFormatters.amount(debit),
                color: const Color(0xFFFF9E9E),
              ),
            ),
          ],
        ),

        if (rateUpdatedAt != null) ...[
          const SizedBox(height: 8),
          Text(
            'آخر تحديث لسعر الصرف: ${DateFormat('yyyy-MM-dd HH:mm').format(rateUpdatedAt!)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.38),
              fontSize: 10.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({required this.icon, required this.onTap, this.tint});

  final IconData icon;
  final VoidCallback onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Icon(
          icon,
          size: 17,
          color: tint ?? Colors.white.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}
