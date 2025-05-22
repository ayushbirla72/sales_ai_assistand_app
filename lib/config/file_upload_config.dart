class FileUploadConfig {
  // Base endpoints
  static const String baseEndpoint = '/files';

  // File upload endpoints
  static const String uploadEndpoint = '$baseEndpoint/upload';
  static const String uploadVoiceSampleEndpoint =
      '$baseEndpoint/upload-salesperson-audio';
  static const String deleteEndpoint = '$baseEndpoint/delete';
  static const String downloadUrlEndpoint = '$baseEndpoint/download-url';
  static const String metadataEndpoint = '$baseEndpoint/metadata';
  static const String listEndpoint = '$baseEndpoint/list';

  // File types
  static const String voiceSampleType = 'voice_sample';
  static const String documentType = 'document';
  static const String imageType = 'image';
  static const String videoType = 'video';

  // File size limits (in bytes)
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const int maxVoiceSampleSize = 5 * 1024 * 1024; // 5MB
  static const int maxImageSize = 2 * 1024 * 1024; // 2MB
  static const int maxVideoSize = 50 * 1024 * 1024; // 50MB

  // Allowed file extensions
  static const Map<String, List<String>> allowedExtensions = {
    voiceSampleType: ['mp3', 'wav', 'm4a', 'aac'],
    documentType: ['pdf', 'doc', 'docx', 'txt'],
    imageType: ['jpg', 'jpeg', 'png', 'gif'],
    videoType: ['mp4', 'mov', 'avi'],
  };

  // Upload settings
  static const int chunkSize = 1024 * 1024; // 1MB chunks for large files
  static const int maxConcurrentUploads = 3;
  static const int uploadTimeout = 30000; // 30 seconds

  // Response fields
  static const String fileIdField = 'file_id';
  static const String fileUrlField = 'file_url';
  static const String downloadUrlField = 'download_url';
  static const String metadataField = 'metadata';
  static const String fileTypeField = 'file_type';
  static const String fileNameField = 'file_name';
  static const String fileSizeField = 'file_size';
  static const String createdAtField = 'created_at';
  static const String updatedAtField = 'updated_at';

  // Error messages
  static const String fileTooLargeError = 'File size exceeds the maximum limit';
  static const String invalidFileTypeError = 'File type not allowed';
  static const String uploadFailedError = 'Failed to upload file';
  static const String deleteFailedError = 'Failed to delete file';
  static const String downloadFailedError = 'Failed to download file';
}
