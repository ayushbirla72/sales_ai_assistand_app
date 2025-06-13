import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/audio_api_service.dart';

class LiveSuggestionsScreen extends StatefulWidget {
  final String meetingTitle;
  final String meetingDuration;
  final int participantCount;
  final String meetingId;
  final String eventId;

  const LiveSuggestionsScreen({
    super.key,
    required this.meetingTitle,
    required this.meetingDuration,
    required this.participantCount,
    required this.meetingId,
    required this.eventId,
  });

  @override
  State<LiveSuggestionsScreen> createState() => _LiveSuggestionsScreenState();
}

class _LiveSuggestionsScreenState extends State<LiveSuggestionsScreen> {
  final List<Map<String, dynamic>> _suggestions = [];
  final ScrollController _scrollController = ScrollController();
  Timer? _waveTimer;
  Timer? _suggestionTimer;
  final _audioApiService = AudioApiService();
  Timer? _chunkTimer;
  final ScrollController _suggestionsController = ScrollController();

  @override
  void initState() {
    super.initState();

    Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final List<dynamic> suggestions =
            await _audioApiService.getSuggestions();

        print("daaaaaaaaaaaaaaaaaaa...... ${suggestions}");

        if (suggestions.isNotEmpty) {
          setState(() {
            for (final suggestion in suggestions) {
              // Use _id['\$oid'] as unique identifier
              String suggestionId = suggestion['_id'] ?? '';

              // Check if this suggestion _id is already in _suggestions
              bool alreadyAdded =
                  _suggestions.any((s) => s['_id'] == suggestionId);

              if (!alreadyAdded && suggestionId.isNotEmpty) {
                _suggestions.add({
                  '_id': suggestionId,
                  'type': 'suggestion',
                  'message': suggestion['suggestion'] ??
                      suggestion['transcript'] ??
                      '',
                  'time': DateTime.now(),
                });
              }
            }
            _scrollToBottom(_suggestionsController);
          });
        }
      } catch (e) {
        print('Error fetching suggestions: $e');
      }
    });
  }

  void _scrollToBottom(ScrollController controller) {
    if (controller.hasClients) {
      controller.animateTo(
        controller.position.maxScrollExtent,
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
