import 'package:flutter/foundation.dart';

@immutable
class LinkedAccountsState {
  final String? phone;
  final bool isPhoneVerified;
  final String? googleEmail;
  final bool isGoogleLinked;

  const LinkedAccountsState({
    this.phone,
    this.isPhoneVerified = false,
    this.googleEmail,
    this.isGoogleLinked = false,
  });

  bool get canUnlinkGoogle => isPhoneVerified && (phone != null && phone!.isNotEmpty);

  LinkedAccountsState copyWith({
    String? phone,
    bool? isPhoneVerified,
    String? googleEmail,
    bool? isGoogleLinked,
  }) {
    return LinkedAccountsState(
      phone: phone ?? this.phone,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      googleEmail: googleEmail ?? this.googleEmail,
      isGoogleLinked: isGoogleLinked ?? this.isGoogleLinked,
    );
  }
}
