/// Central typed route names and path definitions for UdyogaSethu.
class AppRoutes {
  AppRoutes._();

  // Root & Auth / Onboarding
  static const String brandIntro = '/brand-intro';
  static const String splash = '/splash';
  static const String intro = '/intro';
  static const String language = '/language';
  static const String roleTree = '/role-tree';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String verifyPhone = '/auth/verify-phone';
  static const String suspended = '/suspended';
  static const String roleConflict = '/role-conflict';
  static const String profileSetupSeeker = '/profile-setup/seeker';
  static const String profileSetupFarmer = '/profile-setup/farmer';
  static const String profileSetupProvider = '/profile-setup/provider';

  // Seeker Shell Tabs
  static const String seekerHome = '/seeker/home';
  static const String seekerJobs = '/seeker/jobs';
  static const String seekerMap = '/seeker/map';
  static const String seekerChat = '/seeker/chat';
  static const String seekerProfile = '/seeker/profile';

  // Provider Shell Tabs
  static const String providerHome = '/provider/home';
  static const String providerWorkers = '/provider/workers';
  static const String providerChat = '/provider/chat';
  static const String providerProfile = '/provider/profile';

  // Provider Job Management
  static const String providerJobNew = '/provider/jobs/new';
  static const String providerJobApplicants = '/provider/jobs/:id/applicants';
  static const String providerJobEdit = '/provider/jobs/:id/edit';
  static const String providerWorkerProfile = '/provider/workers/:id';
  static const String providerBooking = '/provider/booking';
  static const String recurringBookings = '/provider/recurring';

  // Farmer Shell Tabs
  static const String farmerHome = '/farmer/home';
  static const String farmerMarket = '/farmer/market';
  static const String farmerChat = '/farmer/chat';
  static const String farmerProfile = '/farmer/profile';
  static const String farmerListings = '/farmer/listings';
  static const String farmerResources = '/farmer/resources';
  static const String farmerVendorResources = '/farmer/vendor-resources';
  static const String subscriptions = '/subscriptions';
  static const String groupOrders = '/group-orders';
  static const String farmerSoilAi = '/farmer/soil-ai';
  static const String farmerPestAi = '/farmer/pest-ai';
  static const String farmerIrrigationAi = '/farmer/irrigation-ai';
  static const String farmerGovtSchemes = '/farmer/govt-schemes';

  // Shared Feature Screens
  static const String settings = '/settings';
  static const String kyc = '/kyc';
  static const String kycDl = '/kyc/dl';
  static const String kycStudent = '/kyc/student';
  static const String kycBank = '/kyc/bank';
  static const String kycBackground = '/kyc/background';
  static const String kycFace = '/kyc/face';
  static const String kycFaceCheck = '/kyc/face-check';
  static const String kycSafetyOnboarding = '/kyc/safety-onboarding';
  static const String digitalId = '/trust/digital-id';
  static const String scanVerify = '/trust/scan-verify';
  static const String trustSafetyCentre = '/trust/safety-centre';
  static const String trustGovernanceRights = '/trust/governance-rights';
  static const String privacyCentre = '/privacy-centre';
  static const String termsAndPrivacy = '/terms-privacy';
  static const String safetyHub = '/safety';
  static const String emergencyContacts = '/safety/contacts';
  static const String jobProtectionClaim = '/safety/claim';
  static const String notifications = '/notifications';
  static const String wallet = '/wallet';
  static const String jobDetail = '/job/:id';
  static const String produceDetail = '/produce/:id';
  static const String activeJob = '/jobs/active/:id';
  static const String jobTicket = '/jobs/ticket/:id';
  static const String attendanceScan = '/jobs/attendance-scan';
  static const String verifyPresence = '/jobs/verify-presence/:id';
  static const String jobCompletion = '/jobs/completion/:id';
  static const String workerSchedule = '/seeker/schedule';
  static const String jobHistory = '/jobs/history';
  static const String favourites = '/favourites';
  static const String paymentCheckout = '/payments/checkout';
  static const String paymentStatus = '/payments/status';
  static const String earningsDashboard = '/earnings';
  static const String savingsGoals = '/earnings/savings-goals';
  static const String cart = '/cart';
  static const String orderCheckout = '/orders/checkout';
  static const String orderConfirmation = '/orders/confirmation/:id';
  static String orderConfirmationWithId(String id) => '/orders/confirmation/$id';
  static const String orderTracking = '/orders/tracking/:id';
  static String orderTrackingWithId(String id) => '/orders/tracking/$id';
  static const String customerOrders = '/orders/my-orders';
  static const String farmerOrders = '/farmer/orders';
  static const String farmerDeliverySlots = '/farmer/delivery-slots';
  static const String chatDetail = '/chat';
  static const String maskedCall = '/call/masked';
  static const String rewards = '/rewards';
  static const String rewardsStore = '/rewards/store';
  static const String community = '/community';
  static const String learning = '/learning';
  static const String learningModule = '/learning/:id';
  static String learningModuleWithId(String id) => '/learning/$id';
  static const String creditReadiness = '/credit-readiness';
  static const String wellness = '/wellness';

  // Guided Demo Routes (gated under Env.isDemoBuild)
  static const String demo = '/demo';
  static const String demoAccounts = '/demo/accounts';
  static const String demoAdminReview = '/demo/admin-review';

  // Debug Routes (gated under kDebugMode)
  static const String devGallery = '/dev/gallery';
  static const String devConnection = '/dev/connection';
  static const String devRole = '/dev/role';
  static const String devAssets = '/dev/assets';
  static const String devEdgeHealth = '/dev/edge-health';
  static const String devLifecycle = '/dev/lifecycle';
  static const String devThumbnails = '/dev/thumbnails';
  static const String devJobVisibility = '/dev/job-visibility';
}
