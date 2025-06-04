import 'package:google_sign_in/google_sign_in.dart';
import 'package:logging/logging.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'base_api_service.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:salse_ai_assistant/config/app_config.dart';
import 'package:salse_ai_assistant/services/meeting_service.dart';

class CalendarSyncService {
  final Logger _logger = Logger('CalendarSyncService');
  final GoogleSignIn _googleSignIn;
  final BaseApiService _apiService = BaseApiService();

  CalendarSyncService(this._googleSignIn);

  /// Sync a meeting to Google Calendar (placeholder)
  Future<void> syncMeetingToGoogleCalendar(Map<String, dynamic> meeting) async {
    // TODO: Implement Google Calendar API integration
    _logger.info('Syncing meeting to Google Calendar: $meeting');
    await Future.delayed(const Duration(seconds: 1));
  }

  /// Fetch events from Google Calendar (today only)
  Future<List<Map<String, dynamic>>> fetchGoogleCalendarEvents() async {
    _logger.info('Fetching today\'s events from Google Calendar');
    final account = await _googleSignIn.signInSilently();
    if (account == null) {
      _logger.warning('User not signed in to Google');
      return [];
    }
    final authHeaders = await account.authHeaders;
    final client = GoogleHttpClient(authHeaders);
    final calendarApi = calendar.CalendarApi(client);
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final events = await calendarApi.events.list(
      "primary",
      timeMin: startOfDay,
      timeMax: endOfDay,
      singleEvents: true,
      orderBy: 'startTime',
    );
    var items = events.items ?? [];
    final timeFormat = DateFormat('hh:mm a');
    print(items[0].organizer?.email);
    var itemsss = [];
    try {
      final eventList = items.map((event) => event.toJson()).toList();
      final response = await _apiService.post(
          AppConfig.googleCalendarEndpointSync,
          body: {'events': eventList});

      print('response from google calendar sync: ${response}');
      print('response type: ${response.runtimeType}');
      print('response is null: ${response == null}');
      print('response is List: ${response is List}');
      if (response != null) {
        print('response length: ${response.length}');
      }

      if (response != null && response is List) {
        _logger.info('Events synced to Google Calendar: $response');
        final List<Map<String, dynamic>> mappedEvents = response.map((event) {
          print('Processing event: $event');
          return {
            'id': event['id'] ?? '',
            'mode': event['mode'] ?? 'offline',
            'eventId': event['eventId'] ?? '',
            'title': event['summary'] ?? 'No Title',
            'startTime': event['start']?['dateTime'] != null
                ? timeFormat.format(
                    DateTime.parse(event['start']['dateTime']).toLocal())
                : event['start']?['date'] != null
                    ? timeFormat.format(
                        DateTime.parse(event['start']['date']).toLocal())
                    : '',
            'endTime': event['end']?['dateTime'] != null
                ? timeFormat
                    .format(DateTime.parse(event['end']['dateTime']).toLocal())
                : event['end']?['date'] != null
                    ? timeFormat
                        .format(DateTime.parse(event['end']['date']).toLocal())
                    : '',
            'isMeetingDetailsUploaded':
                event['isMeetingDetailsUploaded'] ?? false,
          };
        }).toList();
        print('Mapped events: $mappedEvents');
        return mappedEvents;
      }
    } catch (e) {
      _logger.severe('Error syncing events to Google Calendar: $e');
      print('Error in fetchGoogleCalendarEvents: $e');
    }

    print('Falling back to original Google Calendar events');
    return items
        .map((event) => {
              'id': event.id,
              'title': event.summary ?? 'No Title',
              'startTime': event.start?.dateTime != null
                  ? timeFormat.format(event.start!.dateTime!.toLocal())
                  : event.start?.date != null
                      ? timeFormat.format(event.start!.date!.toLocal())
                      : '',
              'endTime': event.end?.dateTime != null
                  ? timeFormat.format(event.end!.dateTime!.toLocal())
                  : event.end?.date != null
                      ? timeFormat.format(event.end!.date!.toLocal())
                      : '',
              'isMeetingDetailsUploaded': event.extendedProperties
                      ?.private?['isMeetingDetailsUploaded'] ??
                  false,
            })
        .toList();
  }

  /// Fetch live meetings that have started today
  Future<List<Map<String, dynamic>>> fetchLiveMeetings() async {
    _logger.info('Fetching live meetings');
    try {
      final response = await _apiService.get(
        '/calendar/today-started-meetings',
      );

      if (response != null && response is List) {
        final dateFormat = DateFormat('yyyy-MM-dd');
        final timeFormat = DateFormat('hh:mm a');
        return response.map((meeting) {
          final startDate = meeting['start']?['dateTime'] != null
              ? DateTime.parse(meeting['start']['dateTime'])
              : null;
          final endDate = meeting['end']?['dateTime'] != null
              ? DateTime.parse(meeting['end']['dateTime'])
              : null;

          // Calculate duration in minutes
          String duration = '';
          if (startDate != null && endDate != null) {
            final difference = endDate.difference(startDate);
            final hours = difference.inHours;
            final minutes = difference.inMinutes % 60;
            if (hours > 0) {
              duration = '$hours hour${hours > 1 ? 's' : ''}';
              if (minutes > 0) {
                duration += ' $minutes min${minutes > 1 ? 's' : ''}';
              }
            } else {
              duration = '$minutes min${minutes > 1 ? 's' : ''}';
            }
          }

          return {
            'id': meeting['_id'] ?? '',
            'eventId': meeting['id'] ?? '',
            'title': meeting['summary'] ?? 'No Title',
            'date': startDate != null ? dateFormat.format(startDate) : '',
            'startTime': startDate != null ? timeFormat.format(startDate) : '',
            'endTime': endDate != null ? timeFormat.format(endDate) : '',
            'duration': duration,
            'creator': meeting['creator']?['email'] ?? '',
            'organizer': meeting['organizer']?['email'] ?? '',
            'status': meeting['status'] ?? '',
            'isMeetingDetailsUploaded':
                meeting['isMeetingDetailsUploaded'] ?? false,
            'autoJoin': meeting['autoJoin'] ?? false,
            'htmlLink': meeting['htmlLink'] ?? '',
            'createdAt': meeting['createdAt'] != null
                ? DateTime.parse(meeting['createdAt'].toString())
                : null,
            'updatedAt': meeting['updatedAt'] != null
                ? DateTime.parse(meeting['updatedAt'].toString())
                : null,
          };
        }).toList();
      }
      return [];
    } catch (e) {
      _logger.severe('Error fetching live meetings: $e');
      print('Error in fetchLiveMeetings: $e');
      return [];
    }
  }

  /// Fetch completed meetings
  Future<List<Map<String, dynamic>>> fetchCompletedMeetings() async {
    _logger.info('Fetching completed meetings');
    try {
      final response = await _apiService.get(
        '/calendar/completed-meetings',
      );

      if (response != null && response is List) {
        final dateFormat = DateFormat('yyyy-MM-dd');
        final timeFormat = DateFormat('hh:mm a');
        return response.map((meeting) {
          final startDate = meeting['start']?['dateTime'] != null
              ? DateTime.parse(meeting['start']['dateTime'])
              : null;
          final endDate = meeting['end']?['dateTime'] != null
              ? DateTime.parse(meeting['end']['dateTime'])
              : null;

          // Calculate duration in minutes
          String duration = '';
          if (startDate != null && endDate != null) {
            final difference = endDate.difference(startDate);
            final hours = difference.inHours;
            final minutes = difference.inMinutes % 60;
            if (hours > 0) {
              duration = '$hours hour${hours > 1 ? 's' : ''}';
              if (minutes > 0) {
                duration += ' $minutes min${minutes > 1 ? 's' : ''}';
              }
            } else {
              duration = '$minutes min${minutes > 1 ? 's' : ''}';
            }
          }

          return {
            'id': meeting['_id'] ?? '',
            'eventId': meeting['id'] ?? '',
            'title': meeting['summary'] ?? 'No Title',
            'date': startDate != null ? dateFormat.format(startDate) : '',
            'startTime': startDate != null ? timeFormat.format(startDate) : '',
            'endTime': endDate != null ? timeFormat.format(endDate) : '',
            'duration': duration,
            'creator': meeting['creator']?['email'] ?? '',
            'organizer': meeting['organizer']?['email'] ?? '',
            'status': meeting['status'] ?? '',
            'isMeetingDetailsUploaded':
                meeting['isMeetingDetailsUploaded'] ?? false,
            'autoJoin': meeting['autoJoin'] ?? false,
            'htmlLink': meeting['htmlLink'] ?? '',
            'createdAt': meeting['createdAt'] != null
                ? DateTime.parse(meeting['createdAt'].toString())
                : null,
            'updatedAt': meeting['updatedAt'] != null
                ? DateTime.parse(meeting['updatedAt'].toString())
                : null,
          };
        }).toList();
      }
      return [];
    } catch (e) {
      _logger.severe('Error fetching completed meetings: $e');
      print('Error in fetchCompletedMeetings: $e');
      return [];
    }
  }
}

/// Helper HTTP client for Google APIs
class GoogleHttpClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleHttpClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }

  @override
  void close() {
    _client.close();
    super.close();
  }
}
