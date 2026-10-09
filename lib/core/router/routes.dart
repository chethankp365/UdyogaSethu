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

  // Debug Routes (gated under kDebugMode)
  static const String devGallery = '/dev/gallery';
  static const String devConnection = '/dev/connection';
  static const String devRole = '/dev/role';
  static const String devAssets = '/dev/assets';
  static const String devEdgeHealth = '/dev/edge-health';
}
