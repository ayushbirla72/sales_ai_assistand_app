import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:salse_ai_assistant/screens/compose_email_screen.dart';
import 'package:salse_ai_assistant/screens/email_view_screen.dart';
import 'package:salse_ai_assistant/services/gmail_sync_service.dart';

class EmailScreen extends StatefulWidget {
  const EmailScreen({super.key});

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GmailSyncService _gmailSyncService = GmailSyncService(GoogleSignIn());
  List<Map<String, dynamic>> _sentEmails = [];
  List<Map<String, dynamic>> _draftEmails = [];
  bool _isLoadingSent = true;
  bool _isLoadingDrafts = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchEmails();
  }

  Future<void> _fetchEmails() async {
    await _fetchSentEmails();
    await _fetchDraftEmails();
  }

  Future<void> _fetchSentEmails() async {
    setState(() {
      _isLoadingSent = true;
    });
    try {
      final emails =
          await _gmailSyncService.fetchEmailsFromGmail(label: 'SENT');
      setState(() {
        _sentEmails = emails;
        _isLoadingSent = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSent = false;
      });
      // Handle error
    }
  }

  Future<void> _fetchDraftEmails() async {
    setState(() {
      _isLoadingDrafts = true;
    });
    try {
      final drafts = await _gmailSyncService.fetchDraftsFromGmail();
      setState(() {
        _draftEmails = drafts;
        _isLoadingDrafts = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDrafts = false;
      });
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emails'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sent'),
            Tab(text: 'Drafts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSentEmailsList(),
          _buildDraftsEmailList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ComposeEmailScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSentEmailsList() {
    if (_isLoadingSent) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_sentEmails.isEmpty) {
      return const Center(child: Text('No sent emails found.'));
    }
    return ListView.builder(
      itemCount: _sentEmails.length,
      itemBuilder: (context, index) {
        final email = _sentEmails[index];
        return ListTile(
          title: Text(email['subject'] ?? 'No Subject'),
          subtitle: Text(email['to'] ?? 'No Recipient'),
          trailing: Text(email['date'] ?? ''),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmailViewScreen(email: email),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDraftsEmailList() {
    if (_isLoadingDrafts) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_draftEmails.isEmpty) {
      return const Center(child: Text('No draft emails found.'));
    }
    return ListView.builder(
      itemCount: _draftEmails.length,
      itemBuilder: (context, index) {
        final email = _draftEmails[index];
        return ListTile(
          title: Text(email['subject'] ?? 'No Subject'),
          subtitle: Text(email['to'] ?? 'No Recipient'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmailViewScreen(
                  email: email,
                  isDraft: true,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
