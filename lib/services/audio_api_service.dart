import 'dart:io';
import 'base_api_service.dart';
import '../config/app_config.dart';

class AudioApiService extends BaseApiService {
  bool _isStreaming = false;
  String? _meetingId;
  String? _eventId;

  AudioApiService({String? baseUrl}) : super(baseUrl: baseUrl);

  // Start streaming audio chunks
  Future<void> startStreaming(String meetingId, String eventId) async {
    _meetingId = meetingId;
    _eventId = eventId;
    _isStreaming = true;
  }

  // Stop streaming audio chunks
  void stopStreaming() {
    _isStreaming = false;
  }

  // Send audio chunk to API
  Future<void> sendAudioChunk(File audioFile) async {
    if (!_isStreaming || _meetingId == null || _eventId == null) return;

    try {
      await uploadFile(
        '/audio/stream',
        audioFile,
        additionalFields: {
          'meetingId': _meetingId!,
          'eventId': _eventId!,
        },
      );
    } catch (e) {
      print('Error sending audio chunk: $e');
      rethrow;
    }
  }

  // Send complete audio file
  Future<Map<String, dynamic>> sendCompleteAudio(File audioFile) async {
    if (_meetingId == null || _eventId == null) {
      throw Exception('No active meeting or event');
    }

    try {
      final response = await uploadFile(
        '/audio/complete',
        audioFile,
        additionalFields: {
          'meetingId': _meetingId!,
          'eventId': _eventId!,
        },
      );

      return response;
    } catch (e) {
      print('Error sending complete audio: $e');
      rethrow;
    }
  }

  // Get transcript for a meeting
  Future<Map<String, dynamic>> getTranscript(
      String meetingId, String eventId) async {
    try {
      final response = await get('/transcript/$meetingId/$eventId');
      return response;
    } catch (e) {
      print('Error getting transcript: $e');
      rethrow;
    }
  }

  // Get suggestions for a meeting
  Future<Map<String, dynamic>> getSuggestions(
      String meetingId, String eventId) async {
    try {
      final response = await get('/suggestions/$meetingId/$eventId');
      return response;
    } catch (e) {
      print('Error getting suggestions: $e');
      rethrow;
    }
  }
}
