import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:logging/logging.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:salse_ai_assistant/services/base_api_service.dart';
import 'package:salse_ai_assistant/config/app_config.dart';

class GmailSyncService {
  final Logger _logger = Logger('GmailSyncService');
  final GoogleSignIn _googleSignIn;
  final BaseApiService _apiService = BaseApiService();

  GmailSyncService(this._googleSignIn);

  /// Fetch recent Gmail emails
  Future<List<Map<String, dynamic>>> fetchEmailsFromGmail(
      {String label = 'INBOX'}) async {
    _logger
        .info('Fetching emails from Gmail (last 24 hours) for label: $label');
    final account = await _googleSignIn.signInSilently();
    if (account == null) {
      _logger.warning('User not signed in to Google');
      return [];
    }

    final authHeaders = await account.authHeaders;
    final client = GoogleHttpClient(authHeaders);
    final gmailApi = gmail.GmailApi(client);

    // Calculate timestamp for 24 hours ago in seconds
    final now = DateTime.now();
    final oneDayAgo = now.subtract(Duration(hours: 78));
    final unixTime = (oneDayAgo.millisecondsSinceEpoch ~/ 1000);

    // Use Gmail search query to filter by date
    final messagesList = await gmailApi.users.messages.list(
      'me',
      maxResults: 50,
      labelIds: [label],
      q: 'after:$unixTime',
    );

    final allMessages = messagesList.messages;

    print("Total messages fetched: ${allMessages?.length ?? 0}");
    print("Messages in ${json.encode(messagesList.toJson())}");

    List<Map<String, dynamic>> emails = [];

    for (final msg in allMessages ?? []) {
      final message = await gmailApi.users.messages.get('me', msg.id!);
      final headers = message.payload?.headers ?? [];

      String? subject = headers
          .firstWhere(
            (h) => h.name?.toLowerCase() == 'subject',
            orElse: () => gmail.MessagePartHeader(name: 'Subject', value: ''),
          )
          .value;

      String? from = headers
          .firstWhere(
            (h) => h.name?.toLowerCase() == 'from',
            orElse: () => gmail.MessagePartHeader(name: 'From', value: ''),
          )
          .value;

      String? to = headers
          .firstWhere(
            (h) => h.name?.toLowerCase() == 'to',
            orElse: () => gmail.MessagePartHeader(name: 'To', value: ''),
          )
          .value;

      String formattedDate = '';
      if (message.internalDate != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(
            int.parse(message.internalDate!));
        formattedDate = DateFormat('yyyy-MM-dd hh:mm a').format(date);
      }

      String body = _getBody(message.payload);

      final emailData = {
        'id': message.id,
        'threadId': message.threadId,
        'subject': subject,
        'from': from,
        'to': to,
        'snippet': message.snippet,
        'date': formattedDate,
        'body': body,
      };

      emails.add(emailData);
    }
    _logger.info('Fetched ${emails.length} emails from Gmail');
    // Optional: Send to your server
    try {
      final response = await _apiService.post(
        "/gmail/list", // Replace with your actual endpoint
        body: {'emails': emails},
      );
      _logger.info('Synced ${emails.length} emails to backend: $response');
    } catch (e) {
      _logger.warning('Failed to sync Gmail emails to backend: $e');
    }

    return emails;
  }

  Future<List<Map<String, dynamic>>> fetchDraftsFromGmail() async {
    _logger.info('Fetching drafts from Gmail');
    final account = await _googleSignIn.signInSilently();
    if (account == null) {
      _logger.warning('User not signed in to Google');
      return [];
    }

    final authHeaders = await account.authHeaders;
    final client = GoogleHttpClient(authHeaders);
    final gmailApi = gmail.GmailApi(client);

    final draftsList = await gmailApi.users.drafts.list('me', maxResults: 50);

    List<Map<String, dynamic>> drafts = [];

    for (final draft in draftsList.drafts ?? []) {
      if (draft.id == null) continue;
      final draftDetails = await gmailApi.users.drafts.get('me', draft.id!);
      final message = draftDetails.message;
      final headers = message?.payload?.headers ?? [];

      String? subject = headers
          .firstWhere(
            (h) => h.name?.toLowerCase() == 'subject',
            orElse: () => gmail.MessagePartHeader(name: 'Subject', value: ''),
          )
          .value;

      String? to = headers
          .firstWhere(
            (h) => h.name?.toLowerCase() == 'to',
            orElse: () => gmail.MessagePartHeader(name: 'To', value: ''),
          )
          .value;

      String body = _getBody(message?.payload);

      final draftData = {
        'id': draft.id,
        'subject': subject,
        'to': to,
        'body': body,
      };

      drafts.add(draftData);
    }
    _logger.info('Fetched ${drafts.length} drafts from Gmail');
    return drafts;
  }

  Future<gmail.Draft> createDraft({
    required String to,
    required String subject,
    required String body,
    String? from,
  }) async {
    final account =
        await _googleSignIn.signIn(); // Use signIn if scopes updated
    if (account == null) throw Exception('User not signed in');

    final client = GoogleHttpClient(await account.authHeaders);
    final gmailApi = gmail.GmailApi(client);

    final rawMessage = '''
From: ${from ?? 'me'}
To: $to
Subject: $subject
Content-Type: text/html; charset="UTF-8"
MIME-Version: 1.0

$body
''';

    final encodedMessage = base64Url
        .encode(utf8.encode(rawMessage))
        .replaceAll('+', '-')
        .replaceAll('/', '_')
        .replaceAll('=', ''); // Remove padding for Gmail

    final draft = gmail.Draft()
      ..message = (gmail.Message()..raw = encodedMessage); // ✅ FIXED

    try {
      return await gmailApi.users.drafts.create(draft, 'me');
    } catch (e) {
      print('Failed to create draft: $e');
      rethrow;
    }
  }

  /// Sends an email directly (without draft)
  Future<gmail.Message> sendEmail({
    required String to,
    required String subject,
    required String body,
    String? from,
    List<http.MultipartFile>? attachments,
  }) async {
    final account = await _googleSignIn.signInSilently();
    if (account == null) throw Exception('User not signed in');

    final client = GoogleHttpClient(await account.authHeaders);
    final gmailApi = gmail.GmailApi(client);

    final boundary = 'boundary-${DateTime.now().millisecondsSinceEpoch}';
    final buffer = StringBuffer();

    buffer.writeln('From: ${from ?? 'me'}');
    buffer.writeln('To: $to');
    buffer.writeln('Subject: $subject');
    buffer.writeln('Content-Type: multipart/mixed; boundary=$boundary');
    buffer.writeln();
    buffer.writeln('--$boundary');
    buffer.writeln('Content-Type: text/html; charset=utf-8');
    buffer.writeln();
    buffer.writeln(body);

    if (attachments != null) {
      for (var file in attachments) {
        final bytes = await file.finalize().toBytes();
        final base64Data = base64.encode(bytes);

        buffer.writeln('\n--$boundary');
        buffer.writeln(
            'Content-Type: ${file.contentType}; name="${file.filename}"');
        buffer.writeln(
            'Content-Disposition: attachment; filename="${file.filename}"');
        buffer.writeln('Content-Transfer-Encoding: base64');
        buffer.writeln();
        buffer.writeln(base64Data);
      }
    }

    buffer.writeln('--$boundary--');

    final message = buffer.toString();

    final encodedMessage = base64Url
        .encode(utf8.encode(message))
        .replaceAll('+', '-')
        .replaceAll('/', '_');

    return gmailApi.users.messages.send(
      gmail.Message()..raw = encodedMessage,
      'me',
    );
  }

  String _getBody(gmail.MessagePart? payload) {
    String body = '';
    if (payload == null) {
      return body;
    }

    if (payload.mimeType == 'text/plain' || payload.mimeType == 'text/html') {
      if (payload.body?.data != null) {
        body = utf8.decode(base64Url.decode(
            payload.body!.data!.replaceAll('-', '+').replaceAll('_', '/')));
      }
    } else if (payload.parts != null) {
      for (var part in payload.parts!) {
        body += _getBody(part);
      }
    }
    return body;
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
