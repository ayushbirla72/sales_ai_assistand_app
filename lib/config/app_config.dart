class AppConfig {
  // API Configuration
  static const String baseUrl = 'http://192.168.1.15:8000/api';
  static const String apiVersion = 'v1';
  static const int apiTimeout = 30000; // 30 seconds
  static const int maxRetries = 3;

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
  static const int maxCacheSize = 100; // maximum number of cached items

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
  static const String registerEndpoint = '/auth/signup';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String logoutEndpoint = '/auth/logout';
  static const String profileEndpoint = '/user/profile';
  static const String meetingsEndpoint = '/meetings';
  static const String voiceSamplesEndpoint = '/voice-samples';

  // File Upload Configuration
  static const int maxFileSize = 10; // MB
  static const List<String> allowedFileTypes = ['mp3', 'wav', 'm4a'];
  static const String uploadEndpoint = '/upload';

  // Meeting Configuration
  static const int defaultMeetingDuration = 60; // minutes
  static const int maxParticipants = 100;
  static const int minParticipants = 2;
  static const int warningThreshold = 5; // minutes before meeting end
  static const bool enableRecording = true;
  static const bool enableChat = true;

  // Voice Sample Configuration
  static const int minRecordingDuration = 30; // seconds
  static const int maxRecordingDuration = 300; // seconds
  static const String recordingFormat = 'mp3';

  // Suggestion Types
  static const Map<String, String> suggestionTypes = {
    'info': 'Information',
    'warning': 'Warning',
    'suggestion': 'Suggestion',
    'action': 'Action Required',
    'success': 'Success',
  };

  // Suggestion Categories
  static const List<String> suggestionCategories = [
    'Meeting Structure',
    'Time Management',
    'Participant Engagement',
    'Technical Issues',
    'Documentation',
    'Follow-up Actions',
  ];

  // UI Configuration
  static const double defaultPadding = 16.0;
  static const double cardBorderRadius = 12.0;
  static const int animationDuration = 300; // milliseconds

  // Colors
  static const Map<String, int> colors = {
    'primary': 0xFF2196F3, // Blue
    'secondary': 0xFF4CAF50, // Green
    'warning': 0xFFFFA000, // Orange
    'error': 0xFFE53935, // Red
    'success': 0xFF43A047, // Green
    'info': 0xFF78909C, // Blue Grey
  };

  // Time Formats
  static const String timeFormat = 'HH:mm';
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';

  // Meeting Templates
  static const Map<String, List<String>> meetingTemplates = {
    'brainstorming': [
      'Ice breaker',
      'Problem statement',
      'Idea generation',
      'Voting',
      'Action items',
    ],
    'statusUpdate': [
      'Progress review',
      'Blockers discussion',
      'Next steps',
      'Action items',
    ],
    'planning': [
      'Objective setting',
      'Resource allocation',
      'Timeline planning',
      'Risk assessment',
      'Action items',
    ],
  };

  // Notification Settings
  static const Map<String, bool> notifications = {
    'meetingReminder': true,
    'suggestionAlerts': true,
    'participantJoins': true,
    'technicalIssues': true,
    'timeWarnings': true,
  };

  // Analytics Configuration
  static const Map<String, int> analyticsThresholds = {
    'speakingTimeWarning': 70, // percentage
    'inactivityWarning': 10, // minutes
    'energyLevelWarning': 30, // percentage
    'participationWarning': 20, // percentage
  };
}
