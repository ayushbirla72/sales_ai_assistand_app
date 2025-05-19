import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MeetingDetailsScreen extends StatefulWidget {
  final String meetingTitle;
  final String meetingDate;

  const MeetingDetailsScreen({
    super.key,
    required this.meetingTitle,
    required this.meetingDate,
  });

  @override
  State<MeetingDetailsScreen> createState() => _MeetingDetailsScreenState();
}

class _MeetingDetailsScreenState extends State<MeetingDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.meetingTitle),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'download_transcript') {
                _downloadTranscript();
              } else if (value == 'download_recording') {
                _downloadRecording();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'download_transcript',
                child: Row(
                  children: [
                    Icon(Icons.description),
                    SizedBox(width: 8),
                    Text('Download Transcript'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'download_recording',
                child: Row(
                  children: [
                    Icon(Icons.video_file),
                    SizedBox(width: 8),
                    Text('Download Recording'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'Analytics'),
            Tab(text: 'Suggestions'),
            Tab(text: 'Transcript'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(),
          _buildAnalyticsTab(),
          _buildSuggestionsTab(),
          _buildTranscriptTab(),
        ],
      ),
    );
  }

  void _downloadTranscript() {
    // TODO: Implement transcript download
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Downloading transcript...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _downloadRecording() {
    // TODO: Implement recording download
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Downloading recording...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Meeting Statistics',
            [
              'Total Duration: 45 minutes',
              'Active Participants: 5',
              'Speaking Time: 35 minutes',
              'Questions Asked: 8',
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Speaking Time Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: 40,
                    title: 'John\n40%',
                    color: Colors.blue,
                    radius: 100,
                  ),
                  PieChartSectionData(
                    value: 25,
                    title: 'Sarah\n25%',
                    color: Colors.green,
                    radius: 100,
                  ),
                  PieChartSectionData(
                    value: 20,
                    title: 'Mike\n20%',
                    color: Colors.orange,
                    radius: 100,
                  ),
                  PieChartSectionData(
                    value: 15,
                    title: 'Others\n15%',
                    color: Colors.purple,
                    radius: 100,
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoCard(
            'Key Metrics',
            [
              'Average Response Time: 2.5 seconds',
              'Interruptions: 3',
              'Silence Duration: 5 minutes',
              'Engagement Score: 85%',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Meeting Overview',
            [
              'Date: ${widget.meetingDate}',
              'Duration: 45 minutes',
              'Participants: 5',
              'Platform: Zoom',
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Key Points',
            [
              'Discussed Q2 sales targets',
              'Reviewed new product features',
              'Set action items for next week',
              'Agreed on follow-up meeting date',
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Action Items',
            [
              'John to prepare sales report by Friday',
              'Sarah to schedule demo with client',
              'Mike to follow up on pricing proposal',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSuggestionCard(
            'Follow-up Actions',
            'Schedule a follow-up meeting to discuss the implementation timeline.',
            Icons.calendar_today,
          ),
          const SizedBox(height: 16),
          _buildSuggestionCard(
            'Resource Allocation',
            'Consider assigning additional team members to the project based on the scope discussed.',
            Icons.people,
          ),
          const SizedBox(height: 16),
          _buildSuggestionCard(
            'Documentation',
            'Create detailed documentation of the discussed features for the development team.',
            Icons.description,
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTranscriptMessage(
          'John (Host)',
          'Welcome everyone to our Q2 planning meeting. Let\'s start with the sales targets.',
          '10:00 AM',
        ),
        _buildTranscriptMessage(
          'Sarah',
          'I\'ve prepared the current numbers. We\'re at 75% of our target.',
          '10:02 AM',
        ),
        _buildTranscriptMessage(
          'Mike',
          'That\'s good progress. What are the main challenges we\'re facing?',
          '10:05 AM',
        ),
        _buildTranscriptMessage(
          'John (Host)',
          'Let\'s discuss the new product features we need to implement.',
          '10:15 AM',
        ),
        _buildTranscriptMessage(
          'Sarah',
          'I\'ve got the feature list ready. Should I share my screen?',
          '10:16 AM',
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<String> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.circle, size: 8),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(String title, String description, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(description),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptMessage(String speaker, String message, String time) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  speaker,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(message),
          ],
        ),
      ),
    );
  }
}
