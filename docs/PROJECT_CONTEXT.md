# UdyogaSethu: Project Context & Architectural Blueprint

## Product Summary
**UdyogaSethu** is a multilingual, trust-centric Flutter + Supabase application for informal workers, job providers, and farmers across India. It bridges local work opportunities with verified trust, enables direct farmer-to-consumer agri-commerce, enforces two-step attendance verification (QR ticket + selfie/GPS), provides protected escrow payments, and offers a multilingual, voice-first user experience.

---

## Role Model & Account Tree

* **Worker Role Branches**:
  1. **Job Seeker**: Informal / Skilled Worker (`informal`), Student Part-Time Worker (`student`), or Flexible Part-Time Worker (`part_time`).
  2. **Job Provider**: Households, site supervisors, and employers who post daily wage jobs, manage applicants, and book verified workers.
* **Farmer Role**: Independent smallholders, agri-producers, dairy farmers, and farm cooperatives selling produce directly and managing farm resources.
* **Admin Role**: Platform governance, verification review queue, fraud monitoring, policy studio, and social impact analytics. Separate administrative access tier.
* **Multi-Role Capability**: A single user account can hold multiple roles (e.g. Job Seeker + Job Provider + Farmer). One role is active at a time, selectable via an in-app Role Switcher. Seeker type can be updated after login.
* **Pre-login Role Tree**: New users navigate the role tree before sign-in; role choice is preserved locally and persisted upon first login.

---

## Technical Stack & Architectural Decisions

* **UI Framework**: Flutter (Latest Stable)
* **State Management**: Flutter Riverpod (without code generation except for l10n)
* **Navigation & Routing**: `go_router` with declarative, role-gated routes
* **Backend Database & Auth**: `supabase_flutter` with PostgreSQL, Row Level Security (RLS), and Storage Buckets
* **Server Logic**: Supabase Edge Functions (Deno / TypeScript) and SQL Stored Procedures
* **AI Assistance**: Gemini API integrated via secure Edge Function (`ai-assist`)
* **Localization**: `flutter_localizations` with ARB files. Primary target: 5 fully translated languages (`en`, `kn`, `hi`, `te`, `ta`). Fallback to `en` for extended languages (`mr`, `bn`) until Phase 10.2.

---

## Directory & Folder Structure

UdyogaSethu uses a **feature-first** modular architecture:

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/       # App colors, typography, assets, API routes
│   ├── theme/           # Light & Dark theme tokens, color schemes
│   ├── router/          # GoRouter configuration, route guards, role redirection
│   ├── services/        # Supabase client, GPS, speech-to-text, camera, storage
│   ├── utils/           # Formatters, validators, localized helpers
│   └── widgets/         # Shared UI components (buttons, chips, cards, mic button)
├── l10n/                # ARB files (app_en.arb, app_kn.arb, app_hi.arb, etc.)
└── features/
    ├── auth/            # Splash, role selection, phone OTP, Google auth
    ├── seeker/          # Seeker home, GPS job map, job details, applications
    ├── provider/        # Job posting, applicant management, worker search
    ├── farmer/          # Mandi prices, farm profile, produce listings, weather radar
    ├── marketplace/     # Produce browsing, cart, checkout, group orders
    ├── verification/    # Aadhaar eKYC, DL verification, face enrollment, QR tickets
    ├── job_execution/   # Active job timer, 2-step verification, completion, no-show
    ├── wallet/          # Balance, escrow protection, UPI checkout, transaction logs
    ├── chat/            # Protected inbox, masked voice proxy, SOS emergency
    ├── rewards/         # XP levels, streaks, badges, merchandise store
    ├── admin/           # Operations dashboard, verification queue, fraud & policy
    └── profile/         # User profile, skills, settings, role switcher
```

Every feature module follows `lib/features/<feature>/{data,domain,presentation}`:
* `data/`: Repositories, Supabase API data sources, DTOs (`fromJson`/`toJson`).
* `domain/`: Business entities, repository interfaces, use cases.
* `presentation/`: Riverpod providers, UI screens, feature-specific widgets.

---

## Naming Conventions

* **Files & Folders**: `snake_case.dart`
* **Classes & Enums**: `PascalCase`
* **Variables & Functions**: `camelCase`
* **Database Tables & Columns**: `snake_case` (e.g. `worker_profiles`, `is_verified`)
* **Localization Keys**: `lowerCamelCase` in `.arb` files

---

## Complete Feature List (1 to 100)

1. **Role-Based Registration**: Custom onboarding paths for Workers, Farmers, Customers/Providers, and Admins.
2. **Profile Creation and Management**: Structured profiles for skills, rates, farm details, and preferences.
3. **Role-Specific Dashboards**: Customized home views and tools tailored to the active user role.
4. **Account Availability Controls**: Toggle online/offline status, working hours, and stock availability.
5. **Multi-Language Application Interface**: Fully translated UI across 5 primary Indian languages.
6. **First-Use Language Selection**: Onboarding language picker with dual English and native scripts.
7. **Global Translation System**: Dynamic locale switcher updating all labels without app restart.
8. **Voice-First Assistant**: One-tap microphone button for natural language command intents.
9. **Multilingual Voice Command Mapping**: Speech recognition mapped to localized command triggers.
10. **Low-Literacy Friendly Simple Mode**: High-contrast, large touch targets with visual icons and voice hints.
11. **Local Services Marketplace**: Proximity-based discovery for informal daily-wage and skilled workers.
12. **Worker Search and Filters**: Filter workers by distance, rating, skill, availability, and verification.
13. **Detailed Worker Profile**: Comprehensive bio, work history, ratings, skills, and verified badges.
14. **Skill Tags and Service Categories**: Structured skill tagging driving match recommendations and pricing.
15. **Worker Job Recommendations**: AI and rule-based job recommendations tailored to location and skills.
16. **Job Acceptance and Rejection**: Realtime job request alerts with accept, decline, and detail workflows.
17. **Job Schedule and Calendar**: Visual timeline of booked shifts preventing double-booking conflicts.
18. **Route and ETA Assistance**: Map routing, travel time estimates, and optimized job sequence hints.
19. **Farmer Registration and Farm Profile**: Verified farm profiles showcasing crops, location, and methods.
20. **Produce Listing Management**: Inventory controls for harvest dates, unit pricing, photos, and stock.
21. **Fresh Produce Marketplace**: Direct farm-to-consumer storefront with freshness tags and pricing.
22. **Produce Search and Filters**: Search produce by distance, organic certification, price, and category.
23. **Shopping Cart and Quantity Management**: Interactive produce cart with delivery option selections.
24. **Delivery Slot and Freshness Manager**: Selectable morning/evening slots with harvest timestamp details.
25. **Produce Order Tracking**: Realtime status pipeline from packed to out for delivery and delivered.
26. **Community/Apartment Group Orders**: Shared neighborhood bulk orders with volume pricing splits.
27. **Recurring Produce Subscriptions**: Daily milk and weekly vegetable box automated subscriptions.
28. **Guided Service Booking Flow**: Step-by-step booking wizard for home and daily-wage services.
29. **Guided Produce Order Flow**: Seamless checkout process for farm produce purchases.
30. **GPS-Based Proximity Matching**: Geospatial querying for nearby jobs, workers, and produce listings.
31. **Geofenced Job Address**: Configurable GPS radius validation for job site attendance checks.
32. **Job and Order Status Timeline**: Visual milestone tracker for active bookings and orders.
33. **Rebooking and Reordering**: One-click repeat bookings for favorite workers and produce sellers.
34. **Subscription for Recurring Services**: Scheduled recurring household maintenance and cleaning.
35. **KYC Document Verification**: Document upload interface for Aadhaar, PAN, and driving licenses.
36. **DigiLocker / eKYC Integration Design**: Mock/sandbox integration flow for verified identity checks.
37. **Masked Aadhaar Verification Result**: Privacy-compliant storage displaying only masked Aadhaar details.
38. **Background Verification Status**: Multi-tier vetting badges for home entry and sensitive job roles.
39. **Face-Verified Login**: On-device selfie check verifying identity against reference profile image.
40. **Digital QR Job Ticket**: BookMyShow-style pass with job details, QR code, and address maps.
41. **Employer QR Attendance Scan**: Site check-in scanner logging employer timestamp and location.
42. **Job Timer Start**: Automated hourly and shift time tracker triggered upon valid QR check-in.
43. **Worker Selfie and GPS Job-Start Verification**: Secondary attendance verification using selfie + GPS.
44. **Two-Step Verified Job Start**: Mandatory two-factor job launch: QR scan + worker selfie/location.
45. **Mid-Job Verification**: Periodic liveness check for high-value or long-duration shift work.
46. **Verified Job Completion**: Dual confirmation protocol stopping timers and releasing escrow funds.
47. **Completion Evidence Upload**: Photo attachment logging completed work for quality records.
48. **Fraud and Anomaly Detection**: Automated flagging for suspicious location hops and failed checks.
49. **Verified Identity Kit and QR Profile**: Printable/digital ID card with scannable verification QR.
50. **Trust and Safety Center**: Educational hub covering safety protocols, rights, and emergency aid.
51. **Multi-Method Payments**: Support for UPI, cards, net banking, wallets, and cash on completion.
52. **Protected/Escrow-Style Payment**: Secure fund holding releasing payments only upon verified job end.
53. **Worker/Farmer Wallet**: Digital ledger displaying available balance, pending escrow, and cashouts.
54. **Earnings Dashboard**: Visual analytics tracking daily earnings, payout trends, and targets.
55. **Transaction Receipts**: Itemized digital receipts detailing platform fees, earnings, and taxes.
56. **Ratings and Reviews**: Post-service rating matrix with quick tag selections and feedback text.
57. **Dispute Reporting**: Structured grievance reporting with evidence upload and status tracking.
58. **Admin Dispute Resolution Panel**: Mediation console showing job timelines, GPS logs, and refund tools.
59. **Notification and Alert Center**: In-app push notifications for booking updates, payments, and alerts.
60. **In-App Communication**: Masked end-to-end messaging preserving privacy between counterparties.
61. **Smart Job Matching**: Algorithmic scoring connecting workers to optimal local job postings.
62. **Fair Wage/Rate Suggestions**: Market-driven rate recommendations ensuring fair daily wages.
63. **Farmer Price Suggestions**: Mandi price benchmarks guiding farmers on competitive pricing bands.
64. **Demand Forecasting for Produce**: Market trend indicators helping farmers plan harvest quantities.
65. **Crop Advisory and Risk Alerts**: Weather alerts and agricultural tips localized by district.
66. **Route Optimisation**: Multi-stop route planning minimizing travel cost for multi-job shifts.
67. **Customer Recommendations**: Personalized worker and farm produce recommendations for buyers.
68. **Voice Assistant Intent Actions**: Intent parser converting voice commands into app actions.
69. **XP Points System**: Gamified reputation points earned via verified work and punctual shifts.
70. **User Levels**: Tiered level progression (Starter, Reliable, Trusted Pro, Community Hero).
71. **Positive Behaviour Streaks**: Visual streak counters rewarding consecutive verified jobs and zero disputes.
72. **Achievement Badges**: Unlockable profile badges highlighting specific skills and safety honors.
73. **Performance-Linked Perks**: Commission discounts and priority search placement for top levels.
74. **Referral Rewards**: Incentive program rewarding users for inviting verified workers and farmers.
75. **Rewards and Merchandise Store**: Physical brand merchandise store redeemable via XP points.
76. **Reward Eligibility and Redemption Tracking**: Order management for redeemed brand gear and kits.
77. **Community Wall**: Local hero spotlights celebrating high-performing workers and farmers.
78. **Training Camps and Events**: Event listings for safety workshops and digital literacy sessions.
79. **Local Community Trust Index**: Geographic trust scoring displaying community safety ratings.
80. **Impact Stories**: Case studies showcasing economic growth and middleman elimination.
81. **Learning and Upskilling Hub**: Micro-courses covering site safety, customer relations, and payments.
82. **Micro-Credentials**: Digital certificates awarded upon passing skill and safety quizzes.
83. **Savings Goal Planner**: Target setting tool helping workers save for personal and equipment goals.
84. **Credit and Financial Inclusion Helper**: Conceptual micro-credit eligibility based on work history.
85. **Worker Wellness and Safety Benefits**: Guidance on insurance schemes and emergency aid resources.
86. **Favourite and Trust Circles**: Personal rosters of preferred workers and trusted repeat buyers.
87. **Admin Operations Dashboard**: High-level platform metrics tracking user growth, GMV, and jobs.
88. **Verification Review Queue**: Manual review console for pending KYC documents and background checks.
89. **Fraud Monitoring Panel**: Suspicious activity tracker flagging location anomalies and account shares.
90. **Policy Studio**: Dynamic configuration panel for commission rates, GPS radii, and verification rules.
91. **Content and Marketplace Moderation**: Moderation workspace for produce listings and reviews.
92. **Trust, Governance, and Rights Page**: Public policy documentation on biometric privacy and user rights.
93. **Social Impact Dashboard**: Analytics suite reporting total direct farmer sales and wage growth.
94. **Guided Demo Scenarios**: One-click demo shortcuts populating mock data for fast evaluator testing.
95. **Responsive Design**: Fluid adaptive layouts optimized for mobile, tablet, and desktop viewports.
96. **Low-Data Mode**: Resource saver reducing image resolutions and disabling heavy animations.
97. **Offline-Aware Job/Order View**: Offline caching maintaining access to active job tickets and addresses.
98. **Empty, Loading, and Error States**: Polished state handlers with retry mechanisms across all screens.
99. **Accessibility Settings**: Scalable typography, high contrast modes, and voice guidance options.
100. **Data Privacy and Consent Controls**: Granular privacy permission toggles for biometric and GPS data.
