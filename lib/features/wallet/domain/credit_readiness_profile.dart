import 'package:flutter/foundation.dart';

enum CreditReadinessBand {
  building,
  developing,
  good,
  strong;

  String get label {
    switch (this) {
      case CreditReadinessBand.building:
        return 'Building';
      case CreditReadinessBand.developing:
        return 'Developing';
      case CreditReadinessBand.good:
        return 'Good';
      case CreditReadinessBand.strong:
        return 'Strong';
    }
  }
}

class ReadinessPillar {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final String statusText;
  final String actionPrompt;
  final int scorePoints;

  const ReadinessPillar({
    required this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.statusText,
    required this.actionPrompt,
    required this.scorePoints,
  });
}

@immutable
class CreditReadinessProfile {
  final int conceptualScore; // 0-100 guidance index
  final CreditReadinessBand band;
  final bool identityVerified;
  final bool bankLinked;
  final double ratingAvg;
  final int ratingCount;
  final int completedJobsCount;
  final int totalEarnedRupees;
  final int accountTenureDays;
  final int disputesCount;
  final List<ReadinessPillar> pillars;
  final List<String> actionableNextSteps;

  const CreditReadinessProfile({
    required this.conceptualScore,
    required this.band,
    required this.identityVerified,
    required this.bankLinked,
    required this.ratingAvg,
    required this.ratingCount,
    required this.completedJobsCount,
    required this.totalEarnedRupees,
    required this.accountTenureDays,
    required this.disputesCount,
    required this.pillars,
    required this.actionableNextSteps,
  });

  factory CreditReadinessProfile.fromMetrics({
    required bool identityVerified,
    required bool bankLinked,
    required double ratingAvg,
    required int ratingCount,
    required int completedJobsCount,
    required int totalEarnedPaise,
    required int accountTenureDays,
    required int disputesCount,
  }) {
    int score = 0;

    // Pillar 1: Verified Identity (25 pts)
    final p1 = ReadinessPillar(
      id: 'identity',
      title: 'Verified Identity',
      description: 'Official Aadhaar eKYC verification status',
      isCompleted: identityVerified,
      statusText: identityVerified ? 'Identity Verified' : 'Unverified',
      actionPrompt: identityVerified
          ? 'Identity authenticated on government records'
          : 'Complete Aadhaar eKYC to establish verified presence',
      scorePoints: identityVerified ? 25 : 5,
    );
    score += p1.scorePoints;

    // Pillar 2: Bank Account Linked (25 pts)
    final p2 = ReadinessPillar(
      id: 'bank',
      title: 'Bank Account & UPI',
      description: 'Traceable bank account or UPI handle for payouts',
      isCompleted: bankLinked,
      statusText: bankLinked ? 'Bank Account Linked' : 'No Bank Linked',
      actionPrompt: bankLinked
          ? 'Payout details linked for formal financial trail'
          : 'Link your bank account to receive official payouts',
      scorePoints: bankLinked ? 25 : 5,
    );
    score += p2.scorePoints;

    // Pillar 3: Work Regularity & Tenure (25 pts)
    final bool regularityOk = completedJobsCount >= 3;
    final int regularityPoints = completedJobsCount >= 10
        ? 25
        : completedJobsCount >= 5
            ? 20
            : completedJobsCount >= 2
                ? 12
                : 5;
    score += regularityPoints;

    final p3 = ReadinessPillar(
      id: 'regularity',
      title: 'Income & Work Consistency',
      description: 'Record of completed gigs and formal settlements',
      isCompleted: regularityOk,
      statusText: '$completedJobsCount jobs completed ($accountTenureDays days on platform)',
      actionPrompt: regularityOk
          ? 'Consistent gig track record established'
          : 'Complete more assignments to demonstrate income stability',
      scorePoints: regularityPoints,
    );

    // Pillar 4: Trust & Ratings (25 pts)
    final bool trustOk = ratingAvg >= 4.0 && disputesCount == 0;
    final int trustPoints = (ratingAvg >= 4.5 && disputesCount == 0)
        ? 25
        : (ratingAvg >= 4.0 && disputesCount == 0)
            ? 20
            : ratingCount > 0
                ? 10
                : 5;
    score += trustPoints;

    final p4 = ReadinessPillar(
      id: 'ratings',
      title: 'Ratings & Dispute Record',
      description: 'Customer ratings and dispute-free service history',
      isCompleted: trustOk,
      statusText: ratingCount > 0
          ? '${ratingAvg.toStringAsFixed(1)} ★ ($ratingCount reviews)'
          : 'No reviews yet',
      actionPrompt: disputesCount > 0
          ? '$disputesCount active dispute(s) on file'
          : trustOk
              ? 'Excellent customer trust maintained'
              : 'Maintain >= 4.0 rating with 0 disputes',
      scorePoints: trustPoints,
    );

    // Determine band
    CreditReadinessBand band;
    if (score >= 80) {
      band = CreditReadinessBand.strong;
    } else if (score >= 60) {
      band = CreditReadinessBand.good;
    } else if (score >= 40) {
      band = CreditReadinessBand.developing;
    } else {
      band = CreditReadinessBand.building;
    }

    final steps = <String>[];
    if (!identityVerified) {
      steps.add('Verify your government ID via Aadhaar eKYC.');
    }
    if (!bankLinked) {
      steps.add('Link and verify a bank account for direct digital payouts.');
    }
    if (completedJobsCount < 5) {
      steps.add('Accept and complete regular assignments to build income history.');
    }
    if (ratingAvg < 4.0 || ratingCount < 3) {
      steps.add('Deliver quality service on time to maintain ratings above 4.0.');
    }
    if (steps.isEmpty) {
      steps.add('Maintain regular activity to keep your digital profile up to date.');
    }

    return CreditReadinessProfile(
      conceptualScore: score.clamp(0, 100),
      band: band,
      identityVerified: identityVerified,
      bankLinked: bankLinked,
      ratingAvg: ratingAvg,
      ratingCount: ratingCount,
      completedJobsCount: completedJobsCount,
      totalEarnedRupees: totalEarnedPaise ~/ 100,
      accountTenureDays: accountTenureDays,
      disputesCount: disputesCount,
      pillars: [p1, p2, p3, p4],
      actionableNextSteps: steps,
    );
  }

  factory CreditReadinessProfile.offline() {
    return const CreditReadinessProfile(
      conceptualScore: 0,
      band: CreditReadinessBand.building,
      identityVerified: false,
      bankLinked: false,
      ratingAvg: 0.0,
      ratingCount: 0,
      completedJobsCount: 0,
      totalEarnedRupees: 0,
      accountTenureDays: 0,
      disputesCount: 0,
      pillars: [],
      actionableNextSteps: [
        'Connect to the internet to sync and refresh your credit readiness score.',
      ],
    );
  }
}

