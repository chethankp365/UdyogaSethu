/// Parsed UPI intent data from standard `upi://pay` QR code string (Prompt D6).
class UpiPaymentData {
  final String payeeVpa;
  final String? payeeName; // Name from QR (labelled "name from QR")
  final double? amount;
  final String currency;
  final String? transactionNote;
  final String? merchantCode;
  final String? transactionRef;
  final String rawUri;
  final bool isValid;
  final String? errorMessage;
  final String? bankVerifiedName;
  final bool isBankVerified;
  final String? bankVerificationError;

  const UpiPaymentData({
    required this.payeeVpa,
    this.payeeName,
    this.amount,
    this.currency = 'INR',
    this.transactionNote,
    this.merchantCode,
    this.transactionRef,
    required this.rawUri,
    required this.isValid,
    this.errorMessage,
    this.bankVerifiedName,
    this.isBankVerified = false,
    this.bankVerificationError,
  });

  factory UpiPaymentData.parse(String uriString) {
    final trimmed = uriString.trim();
    if (!trimmed.toLowerCase().startsWith('upi://pay')) {
      // Check if it's a bare VPA string like name@upi
      if (RegExp(r'^[\w.\-]+@[\w.\-]+$').hasMatch(trimmed)) {
        return UpiPaymentData(
          payeeVpa: trimmed,
          rawUri: trimmed,
          isValid: true,
        );
      }
      return UpiPaymentData(
        payeeVpa: '',
        rawUri: uriString,
        isValid: false,
        errorMessage: 'Invalid QR Code: Not a valid UPI code. Must start with upi://pay.',
      );
    }

    try {
      final uri = Uri.parse(trimmed);
      final params = uri.queryParameters;

      final pa = params['pa'] ?? '';
      final pn = params['pn'];
      final amStr = params['am'];
      final cu = params['cu'] ?? 'INR';
      final tn = params['tn'];
      final mc = params['mc'];
      final tr = params['tr'];

      if (pa.isEmpty || !pa.contains('@')) {
        return UpiPaymentData(
          payeeVpa: pa,
          rawUri: uriString,
          isValid: false,
          errorMessage: 'Invalid UPI QR: Payee UPI ID (pa) is missing or invalid.',
        );
      }

      double? parsedAmount;
      if (amStr != null && amStr.isNotEmpty) {
        parsedAmount = double.tryParse(amStr);
      }

      return UpiPaymentData(
        payeeVpa: pa,
        payeeName: pn,
        amount: parsedAmount,
        currency: cu,
        transactionNote: tn,
        merchantCode: mc,
        transactionRef: tr,
        rawUri: uriString,
        isValid: true,
      );
    } catch (e) {
      return UpiPaymentData(
        payeeVpa: '',
        rawUri: uriString,
        isValid: false,
        errorMessage: 'Failed to parse UPI QR URI: $e',
      );
    }
  }

  int? get amountPaise => amount != null ? (amount! * 100).round() : null;

  String get formattedAmount => amount != null ? '₹${amount!.toStringAsFixed(2)}' : 'Open Amount';

  UpiPaymentData copyWith({
    String? payeeVpa,
    String? payeeName,
    double? amount,
    String? currency,
    String? transactionNote,
    String? merchantCode,
    String? transactionRef,
    String? rawUri,
    bool? isValid,
    String? errorMessage,
    String? bankVerifiedName,
    bool? isBankVerified,
    String? bankVerificationError,
  }) {
    return UpiPaymentData(
      payeeVpa: payeeVpa ?? this.payeeVpa,
      payeeName: payeeName ?? this.payeeName,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      transactionNote: transactionNote ?? this.transactionNote,
      merchantCode: merchantCode ?? this.merchantCode,
      transactionRef: transactionRef ?? this.transactionRef,
      rawUri: rawUri ?? this.rawUri,
      isValid: isValid ?? this.isValid,
      errorMessage: errorMessage ?? this.errorMessage,
      bankVerifiedName: bankVerifiedName ?? this.bankVerifiedName,
      isBankVerified: isBankVerified ?? this.isBankVerified,
      bankVerificationError: bankVerificationError ?? this.bankVerificationError,
    );
  }
}
