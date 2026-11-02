import 'package:udyogasethu/features/provider/domain/provider_job.dart';
import 'package:udyogasethu/features/seeker/domain/job_detail.dart';
import 'package:udyogasethu/features/seeker/domain/job_pin.dart';
import 'package:udyogasethu/features/seeker/domain/job_recommendation.dart';

/// Presentation-ready realistic demo job dataset for UdyogaSethu.
/// Covers Delivery, Construction, Cleaning, Retail, Cooking, Farm work, Driving,
/// Electrical, Plumbing, and Part-time/Daily-wage opportunities across Bangalore.
/// All entries are deterministic, idempotent, and flagged as demonstration content.
class DemoJobsData {
  DemoJobsData._();

  // Demo Provider IDs from supabase/seed/seed_demo.sql
  static const String providerAnandSharma = '00000000-0000-0000-0000-000000000201'; // v_p1 (+919900000201)
  static const String providerMeeraReddy = '00000000-0000-0000-0000-000000000202';  // v_p2 (+919900000202)
  static const String providerSureshSai = '00000000-0000-0000-0000-000000000203';   // v_p3 (+919900000203)
  static const String farmerGowda = '00000000-0000-0000-0000-000000000301';         // v_f1 (+919900000301)
  static const String farmerRamakrishna = '00000000-0000-0000-0000-000000000303';   // v_f3 (+919900000303)

  // 14 Canonical Demo Job UUIDs
  static const String j1 = '55555555-5555-4555-8555-555555555501';
  static const String j2 = '55555555-5555-4555-8555-555555555502';
  static const String j3 = '55555555-5555-4555-8555-555555555503';
  static const String j4 = '55555555-5555-4555-8555-555555555504';
  static const String j5 = '55555555-5555-4555-8555-555555555505';
  static const String j6 = '55555555-5555-4555-8555-555555555506';
  static const String j7 = '55555555-5555-4555-8555-555555555507';
  static const String j8 = '55555555-5555-4555-8555-555555555508';
  static const String j9 = '55555555-5555-4555-8555-555555555509';
  static const String j10 = '55555555-5555-4555-8555-555555555510';
  static const String j11 = '55555555-5555-4555-8555-555555555511';
  static const String j12 = '55555555-5555-4555-8555-555555555512';
  static const String j13 = '55555555-5555-4555-8555-555555555513';
  static const String j14 = '55555555-5555-4555-8555-555555555514';

  static final List<JobRecommendation> recommendations = [
    JobRecommendation(
      id: j1,
      providerId: providerSureshSai,
      title: 'Commercial Electrician Helper',
      categoryIcon: 'electrical_services',
      categorySlug: 'electrician',
      employerName: 'Sai Electricals & Trade',
      employerVerified: true,
      employerRating: 4.9,
      wagePaise: 88000,
      wageType: 'daily',
      distanceM: 1800,
      addressText: 'Shop 12, 14th Main, HSR Layout Sector 1',
      score: 96,
      reasons: ['Skill Match: Wiring', 'Close to your location (1.8 km)', 'Escrow Guaranteed'],
      studentsOk: false,
      startAt: DateTime.now().add(const Duration(hours: 14)),
      slotsTotal: 2,
      slotsFilled: 0,
    ),
    JobRecommendation(
      id: j5,
      providerId: providerSureshSai,
      title: 'E-Commerce Parcel Delivery Executive',
      categoryIcon: 'local_shipping',
      categorySlug: 'delivery',
      employerName: 'FastTrack Express Hub',
      employerVerified: true,
      employerRating: 4.8,
      wagePaise: 70000,
      wageType: 'daily',
      distanceM: 1200,
      addressText: '80 Feet Road, Koramangala 4th Block',
      score: 94,
      reasons: ['Immediate Start', 'Flexible Shifts', 'Fuel Allowance Included'],
      studentsOk: true,
      isStudentFriendly: true,
      startAt: DateTime.now().add(const Duration(hours: 16)),
      slotsTotal: 3,
      slotsFilled: 1,
    ),
    JobRecommendation(
      id: j2,
      providerId: providerSureshSai,
      title: 'Construction Site Helper & Mixer',
      categoryIcon: 'construction',
      categorySlug: 'construction',
      employerName: 'Sharma Builders & Contractors',
      employerVerified: true,
      employerRating: 4.9,
      wagePaise: 75000,
      wageType: 'daily',
      distanceM: 2400,
      addressText: 'Site #45, 80 Feet Road, Koramangala',
      score: 92,
      reasons: ['Daily Overtime Available', 'Safety Gear Provided', 'Verified Contractor'],
      studentsOk: false,
      startAt: DateTime.now().add(const Duration(days: 1, hours: 8)),
      slotsTotal: 4,
      slotsFilled: 1,
    ),
    JobRecommendation(
      id: j3,
      providerId: providerAnandSharma,
      title: 'Residential Plumbing & Pipe Repair',
      categoryIcon: 'plumbing',
      categorySlug: 'plumbing',
      employerName: 'Dr. Anand Sharma',
      employerVerified: true,
      employerRating: 4.9,
      wagePaise: 90000,
      wageType: 'daily',
      distanceM: 3100,
      addressText: 'Residence #102, 4th Main, Jayanagar 4th Block',
      score: 90,
      reasons: ['High Day Rate: ₹900', 'Tools Provided', 'Direct Escrow Lock'],
      studentsOk: false,
      startAt: DateTime.now().add(const Duration(days: 1, hours: 9)),
      slotsTotal: 1,
      slotsFilled: 0,
    ),
    JobRecommendation(
      id: j6,
      providerId: providerMeeraReddy,
      title: 'Apartment Deep Cleaning Helper',
      categoryIcon: 'cleaning_services',
      categorySlug: 'cleaner',
      employerName: 'CleanPro Facility Services',
      employerVerified: true,
      employerRating: 4.8,
      wagePaise: 65000,
      wageType: 'daily',
      distanceM: 2800,
      addressText: 'Sobha Sunbeam, 100 Feet Road, Indiranagar',
      score: 89,
      reasons: ['6-Hour Shift', 'Materials Provided', 'Same-day Payout'],
      studentsOk: false,
      startAt: DateTime.now().add(const Duration(days: 1, hours: 10)),
      slotsTotal: 2,
      slotsFilled: 0,
    ),
    JobRecommendation(
      id: j4,
      providerId: providerMeeraReddy,
      title: 'Interior Wall Painting Assistant',
      categoryIcon: 'format_paint',
      categorySlug: 'painting',
      employerName: 'Reddy Villa Estates',
      employerVerified: true,
      employerRating: 4.8,
      wagePaise: 80000,
      wageType: 'daily',
      distanceM: 2200,
      addressText: 'Reddy Villa #88, 5th Block, Koramangala',
      score: 88,
      reasons: ['2-Day Booking', 'Lunch Provided', 'Repeat Employer'],
      studentsOk: false,
      startAt: DateTime.now().add(const Duration(days: 2, hours: 8)),
      slotsTotal: 2,
      slotsFilled: 0,
    ),
    JobRecommendation(
      id: j7,
      providerId: providerAnandSharma,
      title: 'Weekend Event Assistant Cook & Prep',
      categoryIcon: 'house',
      categorySlug: 'domestic_help',
      employerName: 'Anand Catering Services',
      employerVerified: true,
      employerRating: 4.9,
      wagePaise: 100000,
      wageType: 'daily',
      distanceM: 2600,
      addressText: 'Anand Party Hall, 12th Main, Koramangala 3rd Block',
      score: 87,
      reasons: ['Premium Wage: ₹1,000/day', 'Meals Included', 'Weekend Work'],
      studentsOk: false,
      startAt: DateTime.now().add(const Duration(days: 2, hours: 14)),
      slotsTotal: 2,
      slotsFilled: 0,
    ),
    JobRecommendation(
      id: j8,
      providerId: farmerGowda,
      title: 'Tomato Harvesting & Crate Sorting',
      categoryIcon: 'agriculture',
      categorySlug: 'agri_labour',
      employerName: 'Gowda Organic Farms',
      employerVerified: true,
      employerRating: 4.9,
      wagePaise: 65000,
      wageType: 'daily',
      distanceM: 14500,
      addressText: 'Gowda Farms Survey #42, Devanahalli Rural',
      score: 85,
      reasons: ['Organic Farm', 'Transportation Pick-up at Toll Gate', 'Tea & Snacks Provided'],
      studentsOk: false,
      startAt: DateTime.now().add(const Duration(days: 1, hours: 7)),
      slotsTotal: 5,
      slotsFilled: 1,
    ),
    JobRecommendation(
      id: j10,
      providerId: providerSureshSai,
      title: 'Part-Time Pickup Van Driver (LMV)',
      categoryIcon: 'directions_car',
      categorySlug: 'driver',
      employerName: 'Sai Logistics & Distribution',
      employerVerified: true,
      employerRating: 4.9,
      wagePaise: 85000,
      wageType: 'daily',
      distanceM: 4200,
      addressText: 'Sai Fleet Depot, Major Unnikrishnan Road, Yelahanka',
      score: 84,
      reasons: ['Morning 6h Shift', 'Vehicle Provided', 'Licence Verified'],
      studentsOk: false,
      startAt: DateTime.now().add(const Duration(days: 1, hours: 6)),
      slotsTotal: 1,
      slotsFilled: 0,
    ),
    JobRecommendation(
      id: j11,
      providerId: providerAnandSharma,
      title: 'Supermarket Inventory & Billing Assistant',
      categoryIcon: 'inventory_2',
      categorySlug: 'domestic_help',
      employerName: 'Anand Supermart & Grocery',
      employerVerified: true,
      employerRating: 4.9,
      wagePaise: 60000,
      wageType: 'daily',
      distanceM: 3200,
      addressText: 'Anand Supermart, 9th Main, Jayanagar 4th Block',
      score: 83,
      reasons: ['Student Friendly', 'Air Conditioned', 'Flexible Hours'],
      studentsOk: true,
      isStudentFriendly: true,
      startAt: DateTime.now().add(const Duration(days: 1, hours: 11)),
      slotsTotal: 2,
      slotsFilled: 0,
    ),
    JobRecommendation(
      id: j12,
      providerId: providerSureshSai,
      title: 'Warehouse Goods Loading & Stacking',
      categoryIcon: 'inventory_2',
      categorySlug: 'loader',
      employerName: 'Sai Central Warehouse',
      employerVerified: true,
      employerRating: 4.9,
      wagePaise: 75000,
      wageType: 'daily',
      distanceM: 3800,
      addressText: 'Binny Mill Goods Shed, Binny Mill Road',
      score: 82,
      reasons: ['Daily Cash Escrow', 'Hydraulic Lift Assisted', 'Safety Shoes Provided'],
      studentsOk: false,
      startAt: DateTime.now().add(const Duration(days: 1, hours: 9)),
      slotsTotal: 6,
      slotsFilled: 2,
    ),
    JobRecommendation(
      id: j9,
      providerId: farmerRamakrishna,
      title: 'Drip Irrigation Pipeline Laying',
      categoryIcon: 'agriculture',
      categorySlug: 'agri_labour',
      employerName: 'Ramakrishnappa Farms',
      employerVerified: true,
      employerRating: 4.7,
      wagePaise: 70000,
      wageType: 'daily',
      distanceM: 16000,
      addressText: 'Ramakrishnappa Agro Field, NH-75, Hoskote',
      score: 81,
      reasons: ['Field Work', 'Free Farm Lunch', 'Guidance Provided'],
      studentsOk: false,
      startAt: DateTime.now().add(const Duration(days: 2, hours: 7)),
      slotsTotal: 3,
      slotsFilled: 0,
    ),
    JobRecommendation(
      id: j13,
      providerId: providerMeeraReddy,
      title: 'Morning Housekeeping & Kitchen Helper',
      categoryIcon: 'house',
      categorySlug: 'domestic_help',
      employerName: 'CleanPro Domestic Care',
      employerVerified: true,
      employerRating: 4.8,
      wagePaise: 40000,
      wageType: 'daily',
      distanceM: 1900,
      addressText: 'Apartment #204, 19th Main, HSR Layout Sector 2',
      score: 80,
      reasons: ['3-Hour Morning Shift (7am-10am)', 'Quiet Household', 'Long-term Opportunity'],
      studentsOk: false,
      startAt: DateTime.now().add(const Duration(days: 1, hours: 7)),
      slotsTotal: 1,
      slotsFilled: 0,
    ),
    JobRecommendation(
      id: j14,
      providerId: providerAnandSharma,
      title: 'Evening Pharmacy Medicine Home Delivery',
      categoryIcon: 'local_shipping',
      categorySlug: 'delivery',
      employerName: 'Dr. Anand Sharma • Medicos',
      employerVerified: true,
      employerRating: 4.9,
      wagePaise: 50000,
      wageType: 'daily',
      distanceM: 3300,
      addressText: 'Sharma Medicos, 11th Main, Jayanagar 3rd Block',
      score: 79,
      reasons: ['Evening 4-Hour Shift', 'Within 4km Radius', 'Bicycle or Two-Wheeler'],
      studentsOk: true,
      isStudentFriendly: true,
      startAt: DateTime.now().add(const Duration(days: 1, hours: 17)),
      slotsTotal: 2,
      slotsFilled: 0,
    ),
  ];

  static final List<JobPin> jobPins = [
    JobPin(
      id: j1,
      providerId: providerSureshSai,
      lat: 12.9121,
      lng: 77.6446,
      title: 'Commercial Electrician Helper',
      categorySlug: 'electrician',
      categoryName: const {'en': 'Electrician', 'kn': 'ಎಲೆಕ್ಟ್ರಿಷಿಯನ್', 'hi': 'इलेक्ट्रिशियन'},
      categoryIcon: 'electrical_services',
      employerName: 'Sai Electricals & Trade',
      employerVerified: true,
      employerRating: 4.9,
      wagePaise: 88000,
      wageType: 'daily',
      slotsTotal: 2,
      slotsFilled: 0,
      distanceM: 1800,
      addressText: 'HSR Layout Sector 1, Bengaluru',
      startAt: DateTime.now().add(const Duration(hours: 14)),
    ),
    JobPin(
      id: j2,
      providerId: providerSureshSai,
      lat: 12.9352,
      lng: 77.6245,
      title: 'Construction Site Helper & Mixer',
      categorySlug: 'construction',
      categoryName: const {'en': 'Construction', 'kn': 'ನಿರ್ಮಾಣ', 'hi': 'निर्माण'},
      categoryIcon: 'construction',
      employerName: 'Sharma Builders & Contractors',
      employerVerified: true,
      employerRating: 4.9,
      wagePaise: 75000,
      wageType: 'daily',
      slotsTotal: 4,
      slotsFilled: 1,
      distanceM: 2400,
      addressText: 'Koramangala 4th Block, Bengaluru',
      startAt: DateTime.now().add(const Duration(days: 1, hours: 8)),
    ),
    JobPin(
      id: j3,
      providerId: providerAnandSharma,
      lat: 12.9250,
      lng: 77.5938,
      title: 'Residential Plumbing & Pipe Repair',
      categorySlug: 'plumbing',
      categoryName: const {'en': 'Plumbing', 'kn': 'ಪ್ಲಂಬಿಂಗ್', 'hi': 'प्लंबिंग'},
      categoryIcon: 'plumbing',
      employerName: 'Dr. Anand Sharma',
      employerVerified: true,
      employerRating: 4.9,
      wagePaise: 90000,
      wageType: 'daily',
      slotsTotal: 1,
      slotsFilled: 0,
      distanceM: 3100,
      addressText: 'Jayanagar 4th Block, Bengaluru',
      startAt: DateTime.now().add(const Duration(days: 1, hours: 9)),
    ),
    JobPin(
      id: j4,
      providerId: providerMeeraReddy,
      lat: 12.9352,
      lng: 77.6245,
      title: 'Interior Wall Painting Assistant',
      categorySlug: 'painting',
      categoryName: const {'en': 'Painting', 'kn': 'ಪೇಂಟಿಂಗ್', 'hi': 'पेंटिंग'},
      categoryIcon: 'format_paint',
      employerName: 'Reddy Villa Estates',
      employerVerified: true,
      employerRating: 4.8,
      wagePaise: 80000,
      wageType: 'daily',
      slotsTotal: 2,
      slotsFilled: 0,
      distanceM: 2200,
      addressText: 'Koramangala 5th Block, Bengaluru',
      startAt: DateTime.now().add(const Duration(days: 2, hours: 8)),
    ),
    JobPin(
      id: j5,
      providerId: providerSureshSai,
      lat: 12.9352,
      lng: 77.6245,
      title: 'E-Commerce Parcel Delivery Executive',
      categorySlug: 'delivery',
      categoryName: const {'en': 'Delivery', 'kn': 'ಡೆಲಿವರಿ', 'hi': 'डिलीवरी'},
      categoryIcon: 'local_shipping',
      employerName: 'FastTrack Express Hub',
      employerVerified: true,
      employerRating: 4.8,
      wagePaise: 70000,
      wageType: 'daily',
      slotsTotal: 3,
      slotsFilled: 1,
      distanceM: 1200,
      addressText: '80 Feet Road, Koramangala, Bengaluru',
      startAt: DateTime.now().add(const Duration(hours: 16)),
    ),
    JobPin(
      id: j6,
      providerId: providerMeeraReddy,
      lat: 12.9784,
      lng: 77.6408,
      title: 'Apartment Deep Cleaning Helper',
      categorySlug: 'cleaner',
      categoryName: const {'en': 'Cleaner', 'kn': 'ಕ್ಲೀನರ್', 'hi': 'सफाईवाला'},
      categoryIcon: 'cleaning_services',
      employerName: 'CleanPro Facility Services',
      employerVerified: true,
      employerRating: 4.8,
      wagePaise: 65000,
      wageType: 'daily',
      slotsTotal: 2,
      slotsFilled: 0,
      distanceM: 2800,
      addressText: '100 Feet Road, Indiranagar, Bengaluru',
      startAt: DateTime.now().add(const Duration(days: 1, hours: 10)),
    ),
    JobPin(
      id: j7,
      providerId: providerAnandSharma,
      lat: 12.9300,
      lng: 77.6280,
      title: 'Weekend Event Assistant Cook & Prep',
      categorySlug: 'domestic_help',
      categoryName: const {'en': 'Domestic Help', 'kn': 'ಮನೆ ಕೆಲಸ', 'hi': 'घरेलू सहायिका'},
      categoryIcon: 'house',
      employerName: 'Anand Catering Services',
      employerVerified: true,
      employerRating: 4.9,
      wagePaise: 100000,
      wageType: 'daily',
      slotsTotal: 2,
      slotsFilled: 0,
      distanceM: 2600,
      addressText: 'Koramangala 3rd Block, Bengaluru',
      startAt: DateTime.now().add(const Duration(days: 2, hours: 14)),
    ),
    JobPin(
      id: j8,
      providerId: farmerGowda,
      lat: 13.2483,
      lng: 77.7127,
      title: 'Tomato Harvesting & Crate Sorting',
      categorySlug: 'agri_labour',
      categoryName: const {'en': 'Agri Labour', 'kn': 'ಕೃಷಿ ಕಾರ್ಮಿಕ', 'hi': 'कृषि मजदूर'},
      categoryIcon: 'agriculture',
      employerName: 'Gowda Organic Farms',
      employerVerified: true,
      employerRating: 4.9,
      wagePaise: 65000,
      wageType: 'daily',
      slotsTotal: 5,
      slotsFilled: 1,
      distanceM: 14500,
      addressText: 'Devanahalli Rural, Bengaluru',
      startAt: DateTime.now().add(const Duration(days: 1, hours: 7)),
    ),
    JobPin(
      id: j10,
      providerId: providerSureshSai,
      lat: 13.1007,
      lng: 77.5963,
      title: 'Part-Time Pickup Van Driver (LMV)',
      categorySlug: 'driver',
      categoryName: const {'en': 'Driver', 'kn': 'ಡ್ರೈವರ್', 'hi': 'ड्राइवर'},
      categoryIcon: 'directions_car',
      employerName: 'Sai Logistics & Distribution',
      employerVerified: true,
      employerRating: 4.9,
      wagePaise: 85000,
      wageType: 'daily',
      slotsTotal: 1,
      slotsFilled: 0,
      distanceM: 4200,
      addressText: 'Major Unnikrishnan Road, Yelahanka, Bengaluru',
      startAt: DateTime.now().add(const Duration(days: 1, hours: 6)),
    ),
    JobPin(
      id: j12,
      providerId: providerSureshSai,
      lat: 12.9650,
      lng: 77.5650,
      title: 'Warehouse Goods Loading & Stacking',
      categorySlug: 'loader',
      categoryName: const {'en': 'Loader', 'kn': 'ಲೋಡರ್', 'hi': 'लोडर'},
      categoryIcon: 'inventory_2',
      employerName: 'Sai Central Warehouse',
      employerVerified: true,
      employerRating: 4.9,
      wagePaise: 75000,
      wageType: 'daily',
      slotsTotal: 6,
      slotsFilled: 2,
      distanceM: 3800,
      addressText: 'Binny Mill Goods Shed, Bengaluru',
      startAt: DateTime.now().add(const Duration(days: 1, hours: 9)),
    ),
  ];

  static JobDetail getJobDetail(String jobId) {
    final rec = recommendations.firstWhere(
      (r) => r.id == jobId,
      orElse: () => recommendations.first,
    );

    return JobDetail(
      id: rec.id,
      providerId: _resolveProviderId(rec.id),
      providerName: rec.employerName,
      providerAvatar: null,
      providerVerified: rec.employerVerified,
      title: rec.title,
      description: _resolveDescription(rec.id),
      categoryName: rec.categorySlug,
      categorySlug: rec.categorySlug,
      categoryIcon: rec.categoryIcon,
      wagePaise: rec.wagePaise,
      wageType: rec.wageType,
      estDurationMinutes: _resolveDurationMinutes(rec.id),
      startAt: rec.startAt ?? DateTime.now().add(const Duration(days: 1)),
      slotsTotal: rec.slotsTotal,
      slotsFilled: rec.slotsFilled,
      materialsProvided: true,
      paymentMode: rec.wageType,
      requirements: {
        'safety_shoes': rec.categorySlug == 'construction' || rec.categorySlug == 'loader',
        'driving_licence': rec.categorySlug == 'driver',
        'smartphone': rec.categorySlug == 'delivery',
      },
      addressText: rec.addressText ?? 'Bengaluru, Karnataka',
      status: 'open',
      isDemo: true,
    );
  }

  static List<ProviderJob> getProviderJobs(String providerId) {
    return recommendations
        .where((r) => _resolveProviderId(r.id) == providerId)
        .map((r) => ProviderJob(
              id: r.id,
              providerId: providerId,
              categoryId: r.categorySlug,
              categoryName: r.categorySlug,
              categoryIcon: r.categoryIcon,
              title: r.title,
              description: _resolveDescription(r.id),
              wageType: r.wageType,
              wagePaise: r.wagePaise,
              estDurationMinutes: _resolveDurationMinutes(r.id),
              startAt: r.startAt ?? DateTime.now(),
              slotsTotal: r.slotsTotal,
              slotsFilled: r.slotsFilled,
              materialsProvided: true,
              paymentMode: r.wageType,
              requirements: const {},
              addressText: r.addressText,
              geofenceRadiusM: 200,
              status: 'open',
              suitableFor: r.studentsOk ? const ['student', 'all'] : const ['all'],
              createdAt: DateTime.now().subtract(const Duration(days: 1)),
            ))
        .toList();
  }

  static String _resolveProviderId(String jobId) {
    switch (jobId) {
      case j3:
      case j7:
      case j11:
      case j14:
        return providerAnandSharma;
      case j4:
      case j6:
      case j13:
        return providerMeeraReddy;
      case j8:
        return farmerGowda;
      case j9:
        return farmerRamakrishna;
      case j1:
      case j2:
      case j5:
      case j10:
      case j12:
      default:
        return providerSureshSai;
    }
  }

  static String _resolveDescription(String jobId) {
    switch (jobId) {
      case j1:
        return 'Sai Electricals requires an experienced commercial electrician helper for wiring installation, conduit fitting, and switchboard termination at HSR commercial complex.';
      case j2:
        return 'Sharma Builders site helper needed for concrete mixing, brick shifting, and scaffolding support at Koramangala residential development site.';
      case j3:
        return 'Dr. Anand Sharma residence needs pipe leak fixing, bathroom tap replacement, and overhead tank inlet fitting. Clean workmanship expected.';
      case j4:
        return 'Reddy Villa interior painting assistant needed for 2-day home refresh project. Primer application, sanding, and masking tape prep work.';
      case j5:
        return 'FastTrack local parcel dispatch and package sorting across Koramangala and HSR Layout. Smartphone with GPS required. Fuel incentive per delivery.';
      case j6:
        return 'CleanPro Services requires 2 cleaners for post-renovation 3BHK flat deep cleaning: floor scrubbing, window wiping, and balcony pressure wash.';
      case j7:
        return 'Anand Catering needs assistant cook for family gathering. Vegetable chopping, roti making, and food counter maintenance. Meals included.';
      case j8:
        return 'Gowda Organic Farms requires farm workers for picking ripe tomatoes, grading by size, and packing into 25kg wooden crates. Morning shift.';
      case j9:
        return 'Assistance required for unrolling drip tubes, fixing lateral emitters, and connecting sub-main valve pipes across 4-acre field. Hoskote rural.';
      case j10:
        return 'Driver needed for morning goods transport (Tata Ace) between city wholesale mandi and local distribution points. Valid LMV license mandatory.';
      case j11:
        return 'Supermarket shelf stocking, barcode scanning, price tag updating, and customer checkout assistance. Basic numeracy required.';
      case j12:
        return 'Daily wage loaders required for unloading FMCG shipment trucks and stacking cartons on pallets in warehouse bay. Hydraulic lift assisted.';
      case j13:
        return 'Morning 3-hour household assistance: floor mopping, kitchen vessel cleaning, and dusting. Friendly family residence in HSR Layout.';
      case j14:
        return 'Local medicine delivery within 4km radius of clinic. Bicycle or two-wheeler required. Shift: 5 PM to 9 PM.';
      default:
        return 'Verified daily-wage opportunity with guaranteed escrow payment protection on UdyogaSethu.';
    }
  }

  static int _resolveDurationMinutes(String jobId) {
    switch (jobId) {
      case j3:
        return 360;
      case j6:
      case j10:
        return 360;
      case j13:
        return 180;
      case j14:
        return 240;
      default:
        return 480; // Standard 8 hours
    }
  }
}
