import 'dart:io';
import 'package:salse_ai_assistant/services/base_api_service.dart';
import 'package:salse_ai_assistant/config/file_upload_config.dart';

class FileUploadService {
  final BaseApiService _apiService;

  FileUploadService({BaseApiService? apiService})
      : _apiService = apiService ?? BaseApiService();

  /// Upload a file to the server
  ///
  /// [file] - The file to upload
  /// [fileName] - Optional custom file name
  /// [fileType] - Type of file (e.g., 'voice_sample', 'document', etc.)
  /// [metadata] - Additional metadata to be stored with the file
  Future<Map<String, dynamic>> uploadSalespersonAudio({
    required File file,
    String? fileName,
    required String fileType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Validate file size
      final fileSize = await file.length();
      if (fileSize > FileUploadConfig.maxFileSize) {
        throw Exception(FileUploadConfig.fileTooLargeError);
      }

      // Validate file type
      final extension = file.path.split('.').last.toLowerCase();
      final allowedExtensions =
          FileUploadConfig.allowedExtensions[fileType] ?? [];
      if (!allowedExtensions.contains(extension)) {
        throw Exception(FileUploadConfig.invalidFileTypeError);
      }

      final additionalFields = {
        FileUploadConfig.fileTypeField: fileType,
        if (metadata != null) ...metadata,
      };

      final response = await _apiService.uploadFile(
        FileUploadConfig.uploadVoiceSampleEndpoint,
        file,
        fileName: fileName,
        additionalFields: additionalFields
            .map((key, value) => MapEntry(key, value.toString())),
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a file from the server
  ///
  /// [fileId] - The ID of the file to delete
  Future<void> deleteFile(String fileId) async {
    try {
      await _apiService.delete('${FileUploadConfig.deleteEndpoint}/$fileId');
    } catch (e) {
      throw Exception(FileUploadConfig.deleteFailedError);
    }
  }

  /// Get file details from the server
  ///
  /// [fileId] - The ID of the file to retrieve
  Future<Map<String, dynamic>> getFile(String fileId) async {
    try {
      final response =
          await _apiService.get('${FileUploadConfig.baseEndpoint}/$fileId');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get all files of a specific type
  ///
  /// [fileType] - Type of files to retrieve
  /// [page] - Page number for pagination
  /// [limit] - Number of items per page
  Future<Map<String, dynamic>> getFilesByType({
    required String fileType,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _apiService.get(
        FileUploadConfig.listEndpoint,
        queryParams: {
          FileUploadConfig.fileTypeField: fileType,
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get file download URL
  ///
  /// [fileId] - The ID of the file to get download URL for
  Future<String> getFileDownloadUrl(String fileId) async {
    try {
      final response = await _apiService
          .get('${FileUploadConfig.downloadUrlEndpoint}/$fileId');
      return response[FileUploadConfig.downloadUrlField];
    } catch (e) {
      throw Exception(FileUploadConfig.downloadFailedError);
    }
  }

  /// Update file metadata
  ///
  /// [fileId] - The ID of the file to update
  /// [metadata] - New metadata to update
  Future<Map<String, dynamic>> updateFileMetadata({
    required String fileId,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final response = await _apiService.put(
        '${FileUploadConfig.metadataEndpoint}/$fileId',
        body: metadata,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
