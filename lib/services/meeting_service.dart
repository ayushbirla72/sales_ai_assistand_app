import 'package:logging/logging.dart';
import 'base_api_service.dart';
import '../config/app_config.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class MeetingService extends BaseApiService {
  final _logger = Logger('MeetingService');

  MeetingService({String? baseUrl}) : super(baseUrl: baseUrl);

  Future<Map<String, dynamic>> createMeeting({
    required String title,
    required String details,
    required String productDetails,
    required List<String> topics,
    required DateTime scheduledTime,
    required int numberOfParticipants,
    String? eventId,
  }) async {
    try {
      final response = await post(
        AppConfig.meetingsEndpoint,
        body: {
          'title': title,
          'description': details,
          'product_details': productDetails,
          'topics': topics,
          'scheduled_time': scheduledTime.toIso8601String(),
          'participants': numberOfParticipants,
          if (eventId != null) 'eventId': eventId,
        },
      );

      return response;
    } catch (e) {
      _logger.severe('Error creating meeting: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMeetings() async {
    try {
      final response = await get(AppConfig.meetingsEndpoint);
      return List<Map<String, dynamic>>.from(response['meetings']);
    } catch (e) {
      _logger.severe('Error fetching meetings: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMeetingDetails(String meetingId) async {
    try {
      final response = await get('${AppConfig.meetingsEndpoint}/$meetingId');
      return response;
    } catch (e) {
      _logger.severe('Error fetching meeting details: $e');
      rethrow;
    }
  }

  Future<void> updateMeeting({
    required String meetingId,
    required Map<String, dynamic> meetingData,
  }) async {
    try {
      await put(
        '${AppConfig.meetingsEndpoint}/$meetingId',
        body: meetingData,
      );
    } catch (e) {
      _logger.severe('Error updating meeting: $e');
      rethrow;
    }
  }

  Future<void> deleteMeeting(String meetingId) async {
    try {
      await delete('${AppConfig.meetingsEndpoint}/$meetingId');
    } catch (e) {
      _logger.severe('Error deleting meeting: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTodayMeetings() async {
    // TODO: Replace with actual API call
    await Future.delayed(const Duration(seconds: 1));
    return [
      {
        'title': 'Team Sync',
        'startTime': '10:00',
        'endTime': '11:00',
      },
      {
        'title': 'Client Call',
        'startTime': '13:00',
        'endTime': '14:00',
      },
    ];
  }
}
