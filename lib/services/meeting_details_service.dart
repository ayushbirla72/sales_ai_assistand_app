import 'package:logging/logging.dart';
import 'base_api_service.dart';
import '../config/app_config.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class MeetingDetailsService extends BaseApiService {
  final _logger = Logger('MeetingService');
  final String meetingId;
  final String userId;
  final String eventId;

  MeetingDetailsService(
      {required this.meetingId, required this.userId, required this.eventId});

  Future<Map<String, dynamic>> fetchMeetingDataApi() async {
    try {
      final response = await get('/sg/meeting-summary/$meetingId');
      print("response: $response");
      return response ?? {};
    } catch (e) {
      _logger.severe('Error fetching meetings: $e');
      rethrow;
    }
  }
}
