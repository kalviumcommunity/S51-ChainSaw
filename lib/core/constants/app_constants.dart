class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'GateKeeper';
  static const String appVersion = '1.0.0';

  // User Roles
  static const String roleGuard = 'guard';
  static const String roleResident = 'resident';
  static const String roleAdmin = 'admin';

  // Auth Providers (Firebase provider IDs)
  static const String providerPhone = 'phone';
  static const String providerEmail = 'password';
  static const String providerGoogle = 'google.com';

  // Auth Provider Display Names
  static const Map<String, String> authProviderNames = {
    providerPhone: 'Phone Number',
    providerEmail: 'Email & Password',
    providerGoogle: 'Google',
  };

  // Auth Provider Icons (Material Icons names)
  static const Map<String, String> authProviderIcons = {
    providerPhone: 'phone',
    providerEmail: 'email',
    providerGoogle: 'g_mobiledata',
  };

  // Visitor Status
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusDenied = 'denied';
  static const String statusCheckedOut = 'checked_out';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String visitorsCollection = 'visitors';
  static const String flatsCollection = 'flats';
  static const String activityLogsCollection = 'activity_logs';
  static const String notificationsCollection = 'notifications';

  // Firestore User Fields
  static const String fieldPhone = 'phone';
  static const String fieldName = 'name';
  static const String fieldRole = 'role';
  static const String fieldFlatNumber = 'flatNumber';
  static const String fieldFcmToken = 'fcmToken';
  static const String fieldCreatedAt = 'createdAt';
  static const String fieldUpdatedAt = 'updatedAt';

  // Firestore Visitor Fields
  static const String fieldVisitorName = 'name';
  static const String fieldVisitorPhone = 'phone';
  static const String fieldVisitorFlat = 'flatNumber';
  static const String fieldVisitorStatus = 'status';
  static const String fieldEntryTime = 'entryTime';
  static const String fieldExitTime = 'exitTime';
  static const String fieldGuardId = 'guardId';
  static const String fieldApprovedBy = 'approvedBy';
  static const String fieldDeniedBy = 'deniedBy';

  // Firestore Flat Fields
  static const String fieldFlatNum = 'flatNumber';
  static const String fieldBlock = 'block';
  static const String fieldResidentIds = 'residentIds';

  // OTP Settings
  static const int otpLength = 6;
  static const int otpTimeoutSeconds = 60;

  // Validation
  static const int phoneNumberLength = 10;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int minPasswordLength = 6;

  // Email Regex
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Phone Regex (digits only)
  static final RegExp phoneRegex = RegExp(r'^[0-9]+$');
}