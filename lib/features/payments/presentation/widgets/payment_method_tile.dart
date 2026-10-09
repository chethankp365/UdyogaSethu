import 'package:flutter/material.dart';
import 'package:udyogasethu/features/payments/domain/payment_models.dart';

class PaymentMethodTile extends StatelessWidget {
  final PaymentMethod method;
  final bool isSelected;
  final int? walletBalancePaise;
  final int requiredAmountPaise;
  final VoidCallback onTap;

  const PaymentMethodTile({
    super.key,
    required this.method,
    required this.isSelected,
    this.walletBalancePaise,
    required this.requiredAmountPaise,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isWallet = method == PaymentMethod.wallet;
    final walletBalance = walletBalancePaise ?? 0;
    final isInsufficientWallet = isWallet && walletBalance < requiredAmountPaise;

    final subtitle = _getSubtitle();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isInsufficientWallet ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0D6548).withValues(alpha: 0.06)
                : (isDark ? const Color(0xFF1E293B) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF0D6548)
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF0D6548)
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  method.icon,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : const Color(0xFF0D6548)),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isInsufficientWallet ? Colors.grey : null,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isInsufficientWallet
                              ? Colors.red[700]
                              : (isDark ? Colors.grey[400] : Colors.grey[600]),
                          fontWeight: isInsufficientWallet ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0D6548) : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF0D6548),
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _getSubtitle() {
    switch (method) {
      case PaymentMethod.upi:
        return 'Instant bank transfer via any UPI app';
      case PaymentMethod.card:
        return 'Visa, Mastercard, RuPay, Maestro';
      case PaymentMethod.wallet:
        final balanceFormatted = PaymentRecord.formatIndianCurrency(walletBalancePaise ?? 0);
        if ((walletBalancePaise ?? 0) < requiredAmountPaise) {
          return 'Available: $balanceFormatted (Insufficient balance)';
        }
        return 'Available balance: $balanceFormatted';
      case PaymentMethod.cash:
        return 'Pay directly to worker after verified completion';
    }
  }
}
