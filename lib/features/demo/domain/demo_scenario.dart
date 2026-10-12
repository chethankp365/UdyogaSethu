import 'package:flutter/material.dart';

/// Represents a single pedagogical step in an evaluator demo scenario.
class DemoStep {
  final String title;
  final String whyItMatters;
  final String targetRoute;
  final String explanation;
  final IconData icon;

  const DemoStep({
    required this.title,
    required this.whyItMatters,
    required this.targetRoute,
    required this.explanation,
    this.icon = Icons.check_circle_outline,
  });
}

/// Represents one of the 5 guided demo scenarios (P10.1).
class DemoScenario {
  final String id;
  final String title;
  final String subtitle;
  final String targetRole;
  final String testUserPhone;
  final String testUserEmail;
  final String testUserName;
  final int estimatedMinutes;
  final List<DemoStep> steps;
  final IconData icon;
  final Color primaryColor;

  const DemoScenario({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.targetRole,
    required this.testUserPhone,
    required this.testUserEmail,
    required this.testUserName,
    required this.estimatedMinutes,
    required this.steps,
    required this.icon,
    required this.primaryColor,
  });
}

/// Static catalog of the 5 canonical demo scenarios using P1.7 seed data.
class DemoScenariosCatalog {
  DemoScenariosCatalog._();

  static const List<DemoScenario> scenarios = [
    // 1. Worker Day Journey
    DemoScenario(
      id: 'worker_day',
      title: 'Worker Day Journey',
      subtitle: 'Experience an informal worker shift from ticket check-in to instant escrow payout',
      targetRole: 'seeker',
      testUserPhone: '+919900000101',
      testUserEmail: 'ramesh@test.com',
      testUserName: 'Ramesh Kumar (Mason & Plumber)',
      estimatedMinutes: 2,
      icon: Icons.engineering_rounded,
      primaryColor: Color(0xFF0F766E),
      steps: [
        DemoStep(
          title: 'Active Job Assignment',
          whyItMatters: 'Verified booking guarantees daily wage and eliminates waiting at roadside chowks.',
          targetRoute: '/seeker/jobs',
          explanation: 'Review the accepted job assignment with agreed daily rate (₹850) and shift details.',
          icon: Icons.assignment_turned_in_outlined,
        ),
        DemoStep(
          title: 'Dynamic QR Ticket & Two-Step Verification',
          whyItMatters: 'Mandatory 2-step check-in (120s rotating QR + worker selfie & geofence) prevents identity theft and ghost workers.',
          targetRoute: '/execution/ticket/66666666-6666-4666-8666-666666666601',
          explanation: 'Inspect the BookMyShow-style ticket pass with employer check-in scanner and fallback PIN.',
          icon: Icons.qr_code_scanner_rounded,
        ),
        DemoStep(
          title: 'Active Shift Timer',
          whyItMatters: 'Authoritative work timer tracks actual hours worked to guarantee fair shift completion.',
          targetRoute: '/execution/active/66666666-6666-4666-8666-666666666601',
          explanation: 'View the active job timer, emergency SOS button, and dual completion protocol.',
          icon: Icons.timer_outlined,
        ),
        DemoStep(
          title: 'Instant Wallet Escrow Payout',
          whyItMatters: 'Protected escrow guarantees workers receive daily wages directly without middleman cuts.',
          targetRoute: '/wallet',
          explanation: 'Inspect the transparent wallet ledger showing net earnings deposited with 5% platform fee deducted.',
          icon: Icons.account_balance_wallet_outlined,
        ),
      ],
    ),

    // 2. Customer Service Booking
    DemoScenario(
      id: 'customer_booking',
      title: 'Customer Service Booking',
      subtitle: 'Discover trusted local workers, rule-based fair wages, and escrow protection',
      targetRole: 'provider',
      testUserPhone: '+919900000201',
      testUserEmail: 'anand@test.com',
      testUserName: 'Dr. Anand Sharma (Household Employer)',
      estimatedMinutes: 2,
      icon: Icons.home_repair_service_rounded,
      primaryColor: Color(0xFF1D4ED8),
      steps: [
        DemoStep(
          title: 'Discover Verified Workers',
          whyItMatters: 'DigiLocker eKYC Aadhaar & DL badges ensure household safety before hiring.',
          targetRoute: '/provider/home',
          explanation: 'Browse nearby vetted workers with transparent ratings, skill tags, and verified badges.',
          icon: Icons.person_search_outlined,
        ),
        DemoStep(
          title: 'Fair Wage Recommendation',
          whyItMatters: 'Transparent district benchmarks protect both employers and workers from price gouging or underpayment.',
          targetRoute: '/provider/post-job',
          explanation: 'View the dynamic fair wage suggestion band (+15% urgency, +5% experience multipliers).',
          icon: Icons.price_check_rounded,
        ),
        DemoStep(
          title: 'Escrow-Protected Booking Hold',
          whyItMatters: '100% escrow protection holds customer funds safely until verified work completion.',
          targetRoute: '/booking/guided',
          explanation: 'Inspect the guided booking wizard with itemized bill breakdown (Daily Wage, Fee, 18% GST).',
          icon: Icons.verified_user_outlined,
        ),
      ],
    ),

    // 3. Farmer Tomato Sale
    DemoScenario(
      id: 'farmer_sale',
      title: 'Farmer Tomato Direct Sale',
      subtitle: 'Farm-to-consumer commerce with APMC Mandi price bands and delivery handover PIN',
      targetRole: 'farmer',
      testUserPhone: '+919900000301',
      testUserEmail: 'gowda@test.com',
      testUserName: 'Gowda Farmer (Devanahalli Smallholder)',
      estimatedMinutes: 2,
      icon: Icons.agriculture_rounded,
      primaryColor: Color(0xFF15803D),
      steps: [
        DemoStep(
          title: 'APMC Mandi Price Benchmark',
          whyItMatters: 'Official mandi benchmarks empower smallholders to set competitive direct rates without commission agents.',
          targetRoute: '/farmer/home',
          explanation: 'Compare local mandi price bands (₹32 - ₹36/kg) for Fresh Organic Tomatoes.',
          icon: Icons.trending_up_rounded,
        ),
        DemoStep(
          title: 'Produce Inventory Management',
          whyItMatters: 'Atomic stock reservations prevent overselling and display harvest recency to buyers.',
          targetRoute: '/farmer/listings',
          explanation: 'Inspect active tomato listings with live stock counters and organic certification badges.',
          icon: Icons.inventory_2_outlined,
        ),
        DemoStep(
          title: 'Farmer Order Board & Handover PIN',
          whyItMatters: '4-digit delivery PIN confirms physical handover before escrow payment release.',
          targetRoute: '/farmer/orders',
          explanation: 'Manage orders across Incoming, Packing, Dispatch, and Delivered stages with PIN verification.',
          icon: Icons.view_kanban_outlined,
        ),
      ],
    ),

    // 4. Community Bulk Order
    DemoScenario(
      id: 'community_bulk',
      title: 'Community Bulk Order',
      subtitle: 'Apartment group purchasing directly from farms with tiered volume savings',
      targetRole: 'farmer',
      testUserPhone: '+919900000202',
      testUserEmail: 'meera@test.com',
      testUserName: 'Meera Reddy (Apartment Group Leader)',
      estimatedMinutes: 2,
      icon: Icons.groups_rounded,
      primaryColor: Color(0xFF7C3AED),
      steps: [
        DemoStep(
          title: 'Subscriptions & Bulk Orders Hub',
          whyItMatters: 'Bundling farm produce orders across an apartment complex cuts logistics cost and lowers produce prices.',
          targetRoute: '/farmer/subscriptions',
          explanation: 'View the active community bulk orders hub featuring volume progress meters and delivery hubs.',
          icon: Icons.local_shipping_outlined,
        ),
        DemoStep(
          title: 'Volume Discount Tier',
          whyItMatters: 'Direct farmer-to-building logistics saves 20-30% compared to traditional retail markups.',
          targetRoute: '/farmer/subscriptions',
          explanation: 'Inspect apartment group order cards tracking collective target thresholds (e.g. 50 kg for tier discount).',
          icon: Icons.percent_rounded,
        ),
      ],
    ),

    // 5. Admin Trust Review
    DemoScenario(
      id: 'admin_trust',
      title: 'Admin Trust Review & Dispute State',
      subtitle: 'Demonstrate seeded review/dispute state and clarify separate Admin Console boundaries',
      targetRole: 'seeker',
      testUserPhone: '+919900000001',
      testUserEmail: 'admin@udyogasethu.org',
      testUserName: 'UdyogaSethu System Admin',
      estimatedMinutes: 2,
      icon: Icons.gavel_rounded,
      primaryColor: Color(0xFFB45309),
      steps: [
        DemoStep(
          title: 'Seeded Review & Dispute Record',
          whyItMatters: 'Escrow funds are immediately frozen whenever an anomaly or dispute is reported, safeguarding both parties.',
          targetRoute: '/demo/admin-review',
          explanation: 'Inspect the seeded dispute case displaying conflicting arrival timestamps and pending review badge.',
          icon: Icons.warning_amber_rounded,
        ),
        DemoStep(
          title: 'Admin Console Boundary Notice',
          whyItMatters: 'Per architecture policy, administrative arbitration occurs strictly in the separate desktop/web Admin project.',
          targetRoute: '/demo/admin-review',
          explanation: 'Review the architectural guarantee: mobile app enforces read-only freeze and does NOT house the admin console.',
          icon: Icons.security_rounded,
        ),
      ],
    ),
  ];
}
