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
  Future<Map<String, dynamic>> sendAudioChunk(File audioFile) async {
    print('Sending audio chunk');
    print(_meetingId);
    print(_eventId);
    print(_isStreaming);
    if (!_isStreaming || _meetingId == null || _eventId == null) return {};

    try {
      var response = await uploadFile(
        '/meet/audio-chunk',
        audioFile,
        fileName: 'chunk_${DateTime.now().millisecondsSinceEpoch}.wav',
        additionalFields: {
          'meetingId': _meetingId!,
          'eventId': _eventId!,
        },
      );
      return response;
    } catch (e) {
      print('Error sending audio chunk: $e');
      rethrow;
    }
  }

  // Send complete audio file and finalize session
  Future<Map<String, dynamic>> sendCompleteAudio(File audioFile) async {
    if (_meetingId == null || _eventId == null) {
      throw Exception('No active meeting or event');
    }

    try {
      print(
          'Sending complete audio to API with meetingId: $_meetingId and eventId: $_eventId');

      final response = await uploadFile(
        '/meet/finalize-session',
        audioFile,
        fileName: 'complete_${DateTime.now().millisecondsSinceEpoch}.wav',
        additionalFields: {
          'meetingId': _meetingId!,
          'eventId': _eventId!,
        },
      );

      print('API Response for complete audio: $response');
      return response;
    } catch (e) {
      print('Error finalizing session: $e');
      rethrow;
    }
  }

  // Get transcript for a meeting
  Future<List> getTranscript() async {
    try {
      if (_meetingId == null || _eventId == null) {
        throw Exception('No active meeting or event');
      }

      final response = await get('/sg/transcript/$_meetingId/$_eventId');
      if (response is List) {
        return response;
      } else {
        return []; // Fallback if API returns wrong format
      }
    } catch (e) {
      print('Error getting transcript: $e');
      rethrow;
    }
  }

  // Get suggestions for a meeting
  Future<List> getSuggestions() async {
    try {
      if (_meetingId == null || _eventId == null) {
        throw Exception('No active meeting or event');
      }

      final response = await get('/sg/suggestions/$_meetingId/$_eventId');
      if (response is List) {
        return response;
      } else {
        return [];
      }
    } catch (e) {
      print('Error getting suggestions: $e');
      rethrow;
    }
  }
}
