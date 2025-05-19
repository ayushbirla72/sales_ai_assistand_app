class AppConfig {
  // API Configuration
  static const String baseUrl = 'https://api.example.com';
  static const String apiVersion = 'v1';
  static const int apiTimeout = 30000; // 30 seconds

  // Authentication Configuration
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const int tokenExpiryTime = 3600; // 1 hour in seconds

  // App Configuration
  static const String appName = 'Sales AI Assistant';
  static const String appVersion = '1.0.0';
  static const int minPasswordLength = 8;
  static const int maxLoginAttempts = 3;

  // Feature Flags
  static const bool enableVoiceRecording = true;
  static const bool enableDarkMode = true;
  static const bool enableNotifications = true;

  // Cache Configuration
  static const int cacheDuration = 3600; // 1 hour in seconds
  static const int maxCacheSize = 50; // MB

  // Error Messages
  static const String networkErrorMessage =
      'Please check your internet connection';
  static const String serverErrorMessage =
      'Something went wrong. Please try again later';
  static const String authErrorMessage =
      'Authentication failed. Please login again';
  static const String validationErrorMessage =
      'Please check your input and try again';

  // Success Messages
  static const String profileUpdateSuccess = 'Profile updated successfully';
  static const String passwordChangeSuccess = 'Password changed successfully';
  static const String meetingCreateSuccess = 'Meeting created successfully';

  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String profileEndpoint = '/user/profile';
  static const String meetingsEndpoint = '/meetings';
  static const String voiceSamplesEndpoint = '/voice-samples';

  // File Upload Configuration
  static const int maxFileSize = 10; // MB
  static const List<String> allowedFileTypes = ['mp3', 'wav', 'm4a'];
  static const String uploadEndpoint = '/upload';

  // Meeting Configuration
  static const int defaultMeetingDuration = 30; // minutes
  static const int maxParticipants = 10;
  static const bool enableRecording = true;
  static const bool enableChat = true;

  // Voice Sample Configuration
  static const int minRecordingDuration = 30; // seconds
  static const int maxRecordingDuration = 300; // seconds
  static const String recordingFormat = 'mp3';
}
