import 'package:flutter/material.dart';

class LiveSuggestionsScreen extends StatefulWidget {
  final String meetingTitle;
  final String meetingDuration;
  final int participantCount;

  const LiveSuggestionsScreen({
    super.key,
    required this.meetingTitle,
    required this.meetingDuration,
    required this.participantCount,
  });

  @override
  State<LiveSuggestionsScreen> createState() => _LiveSuggestionsScreenState();
}

class _LiveSuggestionsScreenState extends State<LiveSuggestionsScreen> {
  final List<Map<String, dynamic>> _suggestions = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Simulate initial suggestions
    _addInitialSuggestions();
    // Start periodic updates
    _startPeriodicUpdates();
  }

  void _addInitialSuggestions() {
    setState(() {
      _suggestions.addAll([
        {
          'type': 'info',
          'message': 'Meeting started ${widget.meetingDuration} ago',
          'time': DateTime.now().subtract(const Duration(minutes: 15)),
        },
        {
          'type': 'suggestion',
          'message':
              '1. Clarify the meeting objectives:\n• Review the main goals for this session\n• Ensure all participants understand their roles\n• Set clear expectations for outcomes',
          'time': DateTime.now().subtract(const Duration(minutes: 14)),
        },
        {
          'type': 'warning',
          'message':
              '2. Participation imbalance detected:\n• John has spoken for 70% of the time\n• Sarah and Mike have been quiet\n• Consider redistributing speaking opportunities',
          'time': DateTime.now().subtract(const Duration(minutes: 13)),
        },
        {
          'type': 'suggestion',
          'message':
              '3. Suggested discussion structure:\n• Start with a brief agenda review\n• Allocate 5 minutes per topic\n• Leave 10 minutes for Q&A\n• End with action item assignment',
          'time': DateTime.now().subtract(const Duration(minutes: 12)),
        },
        {
          'type': 'info',
          'message':
              '4. Current progress:\n• Completed: Introduction and context\n• In progress: Main discussion points\n• Pending: Action items and next steps',
          'time': DateTime.now().subtract(const Duration(minutes: 11)),
        },
        {
          'type': 'suggestion',
          'message':
              '5. Engagement strategies:\n• Use breakout rooms for smaller discussions\n• Implement a round-robin speaking order\n• Encourage written feedback in chat',
          'time': DateTime.now().subtract(const Duration(minutes: 10)),
        },
      ]);
    });
  }

  void _startPeriodicUpdates() {
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          final randomSuggestions = [
            {
              'type': 'suggestion',
              'message':
                  '1. Meeting energy optimization:\n• Consider a 2-minute stretch break\n• Switch to a more interactive format\n• Use polls to engage participants',
              'time': DateTime.now(),
            },
            {
              'type': 'warning',
              'message':
                  '2. Time management alert:\n• 30% of allocated time remaining\n• 2 agenda items pending\n• Consider prioritizing key topics',
              'time': DateTime.now(),
            },
            {
              'type': 'suggestion',
              'message':
                  '3. Documentation recommendations:\n• Capture key decisions made\n• Document action items with owners\n• Share meeting summary within 24 hours',
              'time': DateTime.now(),
            },
            {
              'type': 'suggestion',
              'message':
                  '4. Communication enhancement:\n• Use visual aids for complex topics\n• Share relevant documents in chat\n• Encourage questions in the Q&A section',
              'time': DateTime.now(),
            },
            {
              'type': 'warning',
              'message':
                  '5. Technical considerations:\n• Check audio quality for all participants\n• Ensure screen sharing is visible\n• Verify chat functionality',
              'time': DateTime.now(),
            },
            {
              'type': 'suggestion',
              'message':
                  '6. Follow-up planning:\n• Schedule next steps discussion\n• Assign action item owners\n• Set deadlines for deliverables',
              'time': DateTime.now(),
            },
          ];

          _suggestions.add(randomSuggestions[
              DateTime.now().second % randomSuggestions.length]);
        });
        _scrollToBottom();
        _startPeriodicUpdates();
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.meetingTitle),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  color: Colors.red,
                  size: 8,
                ),
                SizedBox(width: 4),
                Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Meeting Info Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoItem(
                    Icons.timer,
                    'Duration',
                    widget.meetingDuration,
                  ),
                  _buildInfoItem(
                    Icons.people,
                    'Participants',
                    widget.participantCount.toString(),
                  ),
                ],
              ),
            ),
          ),
          // Chat-like suggestions
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return _buildSuggestionBubble(suggestion);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionBubble(Map<String, dynamic> suggestion) {
    final Color bubbleColor;
    final IconData icon;
    final Color iconColor;

    switch (suggestion['type']) {
      case 'warning':
        bubbleColor = Colors.orange.withOpacity(0.1);
        icon = Icons.warning;
        iconColor = Colors.orange;
        break;
      case 'suggestion':
        bubbleColor = Colors.blue.withOpacity(0.1);
        icon = Icons.lightbulb;
        iconColor = Colors.blue;
        break;
      default:
        bubbleColor = Colors.grey.withOpacity(0.1);
        icon = Icons.info;
        iconColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: bubbleColor,
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(suggestion['message']),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(suggestion['time']),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
