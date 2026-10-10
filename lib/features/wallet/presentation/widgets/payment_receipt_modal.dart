import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/features/wallet/domain/wallet_transaction.dart';

class PaymentReceiptModal extends StatelessWidget {
  final WalletTransaction transaction;

  const PaymentReceiptModal({
    super.key,
    required this.transaction,
  });

  static Future<void> show(BuildContext context, WalletTransaction transaction) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PaymentReceiptModal(transaction: transaction),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareReceipt(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy, h:mm a').format(transaction.createdAt);
    final receiptText = '''
🧾 UdyogaSethu Payment Receipt
================================
Status: ${transaction.status.toUpperCase()} (Escrow Cleared)
Type: ${transaction.title}
Amount: ${transaction.formattedSignedAmount}
Transaction ID: ${transaction.id}
Bank Reference / UTR: ${transaction.utrNumber}
Date & Time: $dateStr

Fee Breakdown:
- Gross Amount: ${transaction.formattedGrossAmount}
- Platform Fee & Protection: ${transaction.formattedFee}
- GST (18%): ${transaction.formattedTax}
- Net Amount: ${transaction.formattedNetAmount}

Protected by UdyogaSethu SafeEscrow
================================
''';
    SharePlus.instance.share(
      ShareParams(
        text: receiptText,
        subject: 'UdyogaSethu Payment Receipt - ${transaction.utrNumber}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    final primaryColor = isCredit ? const Color(0xFF0D6548) : const Color(0xFF1E293B);
    final amountColor = isCredit ? const Color(0xFF00875A) : const Color(0xFFDC2626);
    final dateStr = DateFormat('dd MMMM yyyy, h:mm:ss a').format(transaction.createdAt);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.paleMint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(transaction.icon, color: primaryColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment Receipt',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            transaction.title,
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Hero Amount Card
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCredit
                        ? [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)]
                        : [const Color(0xFFFEF2F2), const Color(0xFFFEE2E2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isCredit ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      transaction.formattedSignedAmount,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: amountColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCredit ? const Color(0xFF00875A) : const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCredit ? Icons.check_circle_rounded : Icons.arrow_outward_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isCredit ? 'Completed • Escrow Settled' : 'Withdrawal Processed',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Transaction Identifiers Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildReceiptRow(
                      context,
                      label: 'Transaction ID',
                      value: transaction.id.isNotEmpty
                          ? transaction.id.substring(0, transaction.id.length >= 18 ? 18 : transaction.id.length)
                          : 'TX-ID-PENDING',
                      fullValueToCopy: transaction.id,
                      canCopy: true,
                    ),
                    const Divider(height: 20),
                    _buildReceiptRow(
                      context,
                      label: 'Bank Reference (UTR / RRN)',
                      value: transaction.utrNumber,
                      fullValueToCopy: transaction.utrNumber,
                      canCopy: true,
                    ),
                    const Divider(height: 20),
                    _buildReceiptRow(
                      context,
                      label: 'Payment Method',
                      value: transaction.type == WalletTransactionType.upiTransfer
                          ? 'Instant UPI Payout'
                          : transaction.type == WalletTransactionType.dailyWage
                              ? 'Direct Worker Escrow'
                              : 'SafeEscrow Ledger',
                    ),
                    const Divider(height: 20),
                    _buildReceiptRow(
                      context,
                      label: 'Date & Time',
                      value: dateStr,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Fee & Protection Breakdown Card
              const Text(
                'FEE & PROTECTION BREAKDOWN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildBreakdownRow('Gross Amount', transaction.formattedGrossAmount),
                    const SizedBox(height: 8),
                    _buildBreakdownRow(
                      'Platform Fee & Safety Coverage',
                      transaction.feePaise > 0 ? transaction.formattedFee : '₹0 (Waived)',
                      isMuted: true,
                    ),
                    const SizedBox(height: 8),
                    _buildBreakdownRow(
                      'GST (18% on platform fee)',
                      transaction.feePaise > 0 ? transaction.formattedTax : '₹0',
                      isMuted: true,
                    ),
                    const Divider(height: 20),
                    _buildBreakdownRow(
                      'Net Amount Credited',
                      transaction.formattedNetAmount,
                      isBold: true,
                      color: amountColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Escrow Milestones / Lifecycle Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shield_rounded, color: Color(0xFF0D6548), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'SafeEscrow Lifecycle',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D6548),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildMilestoneStep('1', 'Funds Locked in Escrow', 'Guaranteed prior to work start', true),
                    _buildMilestoneStep('2', 'Site Attendance & Verification', 'Geo-verified completion confirmed', true),
                    _buildMilestoneStep('3', 'Instant Ledger Release', 'Credited directly to available balance', true, isLast: true),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0xFF0D6548)),
                      ),
                      icon: const Icon(Icons.share_outlined, size: 18, color: Color(0xFF0D6548)),
                      label: const Text(
                        'Share Receipt',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D6548)),
                      ),
                      onPressed: () => _shareReceipt(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6548),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(
    BuildContext context, {
    required String label,
    required String value,
    String? fullValueToCopy,
    bool canCopy = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            if (canCopy) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: () => _copyToClipboard(context, fullValueToCopy ?? value, label),
                child: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF0D6548)),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildBreakdownRow(String label, String value, {bool isMuted = false, bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isMuted ? AppColors.textMuted : AppColors.textDark,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? (isMuted ? AppColors.textMuted : AppColors.textDark),
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneStep(String num, String title, String subtitle, bool isDone, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isDone ? const Color(0xFF0D6548) : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : Text(num, style: const TextStyle(fontSize: 10, color: Colors.white)),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 22,
                color: isDone ? const Color(0xFF0D6548) : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D6548)),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
