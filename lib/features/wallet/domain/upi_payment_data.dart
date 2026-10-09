/// Parsed UPI intent data from standard `upi://pay` QR code string.
class UpiPaymentData {
  final String payeeVpa;
  final String? payeeName;
  final double? amount;
  final String currency;
  final String? transactionNote;
  final String? merchantCode;
  final String? transactionRef;
  final String rawUri;
  final bool isValid;

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

      double? parsedAmount;
      if (amStr != null && amStr.isNotEmpty) {
        parsedAmount = double.tryParse(amStr);
      }

      final valid = pa.isNotEmpty && pa.contains('@');

      return UpiPaymentData(
        payeeVpa: pa,
        payeeName: pn,
        amount: parsedAmount,
        currency: cu,
        transactionNote: tn,
        merchantCode: mc,
        transactionRef: tr,
        rawUri: uriString,
        isValid: valid,
      );
    } catch (_) {
      return UpiPaymentData(
        payeeVpa: '',
        rawUri: uriString,
        isValid: false,
      );
    }
  }

  int? get amountPaise => amount != null ? (amount! * 100).round() : null;

  String get formattedAmount => amount != null ? '₹${amount!.toStringAsFixed(2)}' : 'Open Amount';
}
