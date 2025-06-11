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
  Future<List<Map<String, dynamic>>> fetchEmailsFromGmail() async {
    _logger.info('Fetching emails from Gmail (last 24 hours)');
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
      labelIds: ['INBOX'],
      q: 'after:$unixTime',
    );

    final sentMessages = await gmailApi.users.messages.list(
      'me',
      maxResults: 50,
      labelIds: ['SENT'],
      q: 'after:$unixTime',
    );

    final allMessages = [...?messagesList.messages, ...?sentMessages.messages];

    print("Total messages fetched: ${allMessages.length}");
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

      final emailData = {
        'id': message.id,
        'threadId': message.threadId,
        'subject': subject,
        'from': from,
        'to': to,
        'snippet': message.snippet,
        'date': formattedDate,
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

  /// Creates a draft email in Gmail
  Future<gmail.Draft> createDraft({
    required String to,
    required String subject,
    required String body,
    String? from,
  }) async {
    final account = await _googleSignIn.signInSilently();
    if (account == null) throw Exception('User not signed in');

    final client = GoogleHttpClient(await account.authHeaders);
    final gmailApi = gmail.GmailApi(client);

    // Construct MIME message
    final message = [
      'From: ${from ?? 'me'}',
      'To: $to',
      'Subject: $subject',
      'Content-Type: text/html; charset=utf-8',
      'MIME-Version: 1.0',
      '',
      body
    ].join('\n');

    // Base64 URL-safe encode
    final encodedMessage = base64Url
        .encode(message.codeUnits)
        .replaceAll('+', '-')
        .replaceAll('/', '_');

    final draft = gmail.Draft()
      ..message = gmail.Message()
      ..message!.raw = encodedMessage;

    return gmailApi.users.drafts.create(draft, 'me');
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
