import 'package:flutter/material.dart';
import 'package:salse_ai_assistant/screens/compose_email_screen.dart';

class EmailViewScreen extends StatelessWidget {
  final Map<String, dynamic> email;
  final bool isDraft;

  const EmailViewScreen({
    super.key,
    required this.email,
    this.isDraft = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(email['subject'] ?? 'No Subject'),
        actions: [
          if (isDraft)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ComposeEmailScreen(
                      email: email,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'From: ${email['from'] ?? 'N/A'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'To: ${email['to'] ?? 'N/A'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Date: ${email['date'] ?? 'N/A'}',
                style: const TextStyle(color: Colors.grey),
              ),
              const Divider(),
              Text(email['body'] ?? 'No content'),
            ],
          ),
        ),
      ),
    );
  }
}
