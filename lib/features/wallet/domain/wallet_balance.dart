/// Domain model representing live wallet balances strictly sourced from `wallet_balances` view.
class WalletBalance {
  final String walletId;
  final int availablePaise;
  final int pendingPaise;
  final int escrowPaise;
  final int rewardPaise;
  final int totalBalancePaise;
  final int todayCreditPaise;

  const WalletBalance({
    required this.walletId,
    required this.availablePaise,
    required this.pendingPaise,
    required this.escrowPaise,
    required this.rewardPaise,
    required this.totalBalancePaise,
    required this.todayCreditPaise,
  });

  factory WalletBalance.zero([String walletId = '']) => WalletBalance(
        walletId: walletId,
        availablePaise: 0,
        pendingPaise: 0,
        escrowPaise: 0,
        rewardPaise: 0,
        totalBalancePaise: 0,
        todayCreditPaise: 0,
      );

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      walletId: (json['wallet_id'] as String?) ?? '',
      availablePaise: (json['available_paise'] as num?)?.toInt() ?? 0,
      pendingPaise: (json['pending_paise'] as num?)?.toInt() ?? 0,
      escrowPaise: (json['escrow_paise'] as num?)?.toInt() ?? 0,
      rewardPaise: (json['reward_paise'] as num?)?.toInt() ?? 0,
      totalBalancePaise: (json['total_balance_paise'] as num?)?.toInt() ?? 0,
      todayCreditPaise: (json['today_credit_paise'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'wallet_id': walletId,
        'available_paise': availablePaise,
        'pending_paise': pendingPaise,
        'escrow_paise': escrowPaise,
        'reward_paise': rewardPaise,
        'total_balance_paise': totalBalancePaise,
        'today_credit_paise': todayCreditPaise,
      };

  double get availableRupees => availablePaise / 100.0;
  double get pendingRupees => pendingPaise / 100.0;
  double get escrowRupees => escrowPaise / 100.0;
  double get rewardRupees => rewardPaise / 100.0;
  double get totalBalanceRupees => totalBalancePaise / 100.0;
  double get todayCreditRupees => todayCreditPaise / 100.0;

  /// Formats amount in rupees using standard Indian numbering system (e.g. ₹15,250 or ₹1,50,000).
  static String formatIndianCurrency(int paise, {bool includeSymbol = true, bool showDecimals = false}) {
    final double rupees = paise / 100.0;
    final bool isNegative = rupees < 0;
    final double absRupees = rupees.abs();
    final int intPart = absRupees.truncate();
    final int fractionPart = ((absRupees - intPart) * 100).round();

    final String intString = intPart.toString();
    String formattedInt;

    if (intString.length <= 3) {
      formattedInt = intString;
    } else {
      final String lastThree = intString.substring(intString.length - 3);
      final String remaining = intString.substring(0, intString.length - 3);

      final StringBuffer buffer = StringBuffer();
      for (int i = 0; i < remaining.length; i++) {
        if (i > 0 && (remaining.length - i) % 2 == 0) {
          buffer.write(',');
        }
        buffer.write(remaining[i]);
      }
      formattedInt = '${buffer.toString()},$lastThree';
    }

    final String sign = isNegative ? '-' : '';
    final String symbol = includeSymbol ? '₹' : '';
    final String decimals = showDecimals ? '.${fractionPart.toString().padLeft(2, '0')}' : '';

    return '$sign$symbol$formattedInt$decimals';
  }

  String get formattedAvailable => formatIndianCurrency(availablePaise);
  String get formattedEscrow => formatIndianCurrency(escrowPaise);
  String get formattedPending => formatIndianCurrency(pendingPaise);
  String get formattedReward => formatIndianCurrency(rewardPaise);
  String get formattedTotal => formatIndianCurrency(totalBalancePaise);
  String get formattedTodayCredit => formatIndianCurrency(todayCreditPaise);
}
