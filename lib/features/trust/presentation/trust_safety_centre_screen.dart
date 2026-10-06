import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:udyogasethu/core/router/routes.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';

class TrustSafetyCentreScreen extends StatelessWidget {
  const TrustSafetyCentreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trust & Safety Centre', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Trust Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.headerGreenDark, Colors.teal.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Your Safety, Privacy & Trust',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'UdyogaSethu enforces end-to-end trust mechanisms: verified identities, biometric protection, tamper-proof QR tickets, escrow payments, and instant emergency support.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 14),

                  // Quick Action Buttons
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => context.push(AppRoutes.digitalId),
                        icon: const Icon(Icons.badge_rounded, size: 16),
                        label: const Text('My Digital ID'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.headerGreenDark,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () => context.push(AppRoutes.scanVerify),
                        icon: const Icon(Icons.qr_code_scanner_rounded, size: 16, color: Colors.white),
                        label: const Text('Scan Worker ID', style: TextStyle(color: Colors.white, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white70),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Trust Principles & Safety Systems',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),

            // 1. KYC & Identity Verification
            _buildSectionTile(
              icon: Icons.fingerprint_rounded,
              color: Colors.blue.shade700,
              title: '1. KYC & DigiLocker Verification',
              description:
                  'Every worker identity is verified through DigiLocker and government-certified KYC. Full 12-digit numbers are never stored; only masked public references (e.g. XXXX-XXXX-4321) exist on our servers.',
            ),
            const SizedBox(height: 10),

            // 2. Face Verification & Liveness
            _buildSectionTile(
              icon: Icons.face_retouching_natural_rounded,
              color: Colors.teal.shade700,
              title: '2. On-Device Face Liveness',
              description:
                  'Face templates are 128-dimensional mathematical feature vectors processed on-device. Photos are discarded immediately after feature extraction. Random blink and head-turn gestures prevent photo spoofing.',
            ),
            const SizedBox(height: 10),

            // 3. QR Tickets & Attendance
            _buildSectionTile(
              icon: Icons.qr_code_2_rounded,
              color: Colors.purple.shade700,
              title: '3. QR Ticket Pass & Job Check-In',
              description:
                  'Daily shifts begin only when the worker scans the employer\'s site QR code or presents their signed Digital ID. Cryptographic tokens expire in 5 minutes to prevent pass transfers.',
            ),
            const SizedBox(height: 10),

            // 4. Ratings & Reviews
            _buildSectionTile(
              icon: Icons.star_half_rounded,
              color: Colors.amber.shade800,
              title: '4. Mutual Ratings & Reviews',
              description:
                  'Workers and providers rate each other after job completion. Ratings are mathematically aggregated across 100% genuine completed jobs. Abuse or false ratings are audited by automated fraud flags.',
            ),
            const SizedBox(height: 10),

            // 5. Protected Payments
            _buildSectionTile(
              icon: Icons.account_balance_wallet_rounded,
              color: Colors.green.shade800,
              title: '5. Protected Escrow Payments',
              description:
                  'Customer payment is held safely in escrow before work begins. Funds are credited directly to the worker\'s verified UPI / bank account only upon verified job completion.',
            ),
            const SizedBox(height: 10),

            // 6. Disputes
            _buildSectionTile(
              icon: Icons.gavel_rounded,
              color: Colors.brown.shade700,
              title: '6. Fair Dispute Resolution',
              description:
                  'Either party can raise a dispute with photo evidence. Escrow funds are paused while trained mediators review time records, GPS coordinates, and arrival proofs.',
            ),
            const SizedBox(height: 10),

            // 7. Emergency & SOS Reporting
            _buildSectionTile(
              icon: Icons.sos_rounded,
              color: Colors.red.shade700,
              title: '7. Emergency SOS & Incident Alert',
              description:
                  'One-touch SOS button instantly alerts designated emergency contacts, platform dispatchers, and local helpline services with live GPS coordinates.',
            ),
            const SizedBox(height: 10),

            // 8. Data Use & Rights
            _buildSectionTile(
              icon: Icons.privacy_tip_rounded,
              color: Colors.indigo.shade700,
              title: '8. Privacy & Data Use Limitations',
              description:
                  'Your data is never sold or used for unauthorized advertising. You can export your full data archive or exercise your right to account erasure under Decision D11 anytime.',
            ),
            const SizedBox(height: 10),

            // 9. Safe Hiring & Working Tips
            _buildSectionTile(
              icon: Icons.lightbulb_outline_rounded,
              color: Colors.deepOrange.shade700,
              title: '9. Safe Hiring & Working Tips',
              description:
                  'Employers: always scan worker\'s QR code before permitting entry to home/site. Workers: confirm job details in app, use masked call proxy, and never accept off-platform cash advances.',
            ),
            const SizedBox(height: 20),

            // Link to Detailed Governance Page
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.policy_rounded, color: Colors.blue),
                ),
                title: const Text('Trust, Governance & User Rights', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Read full statutory limits, biometric consent & grievance contacts', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(AppRoutes.trustGovernanceRights),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
