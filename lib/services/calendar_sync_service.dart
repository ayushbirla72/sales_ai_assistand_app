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
