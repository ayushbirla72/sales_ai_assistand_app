import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

import '../services/meeting_details_service.dart';

class MeetingDetailsScreen extends StatefulWidget {
  final String meetingTitle;
  final String meetingDate;
  final String meetingId;
  final String eventId;
  final String userId;

  const MeetingDetailsScreen({
    super.key,
    required this.meetingTitle,
    required this.meetingDate,
    required this.meetingId,
    required this.eventId,
    required this.userId,
  });

  @override
  State<MeetingDetailsScreen> createState() => _MeetingDetailsScreenState();
}

class _MeetingDetailsScreenState extends State<MeetingDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String summary = '';
  // List<Map<String, dynamic>> suggestion = [];
  Map<String, dynamic> suggestion = {};

  List<Map<String, dynamic>> transcript = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    fetchMeetingData();
  }

  Future<void> fetchMeetingData() async {
    print("fetching meeting data");
    print("meetingId: ${widget.meetingId}");
    print("eventId: ${widget.eventId}");
    print("userId: ${widget.userId}");

    final meetingDetailsService = MeetingDetailsService(
      meetingId: widget.meetingId,
      userId: widget.userId,
      eventId: widget.eventId,
    );
    try {
      final meetingData = await meetingDetailsService.fetchMeetingDataApi();
      if (mounted && meetingData != null) {
        setState(() {
          summary = meetingData['summary'] as String? ?? '';
          suggestion = meetingData['suggestion'];

          final result = meetingData['transcript'];
          if (result is List) {
            transcript = List<Map<String, dynamic>>.from(result);
          } else {
            transcript = [];
            print(
                "Warning: 'result' is not a list. Actual type: ${result.runtimeType}");
          }

          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message: ${e.toString()}'),
            backgroundColor: Colors.amberAccent,
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
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

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Text(summary, style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _buildSuggestionsTab() {
    final Map<String, dynamic> data = suggestion;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.entries.map((entry) {
          final isActionItems = entry.key.contains("Action Items");

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 12),
              isActionItems
                  ? _buildActionItemCards(entry.value)
                  : Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        entry.value,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionItemCards(String value) {
    final lines = value.trim().split('\n');
    return Column(
      children: lines.map((line) {
        final parts = line.split('|').map((p) => p.trim()).toList();
        if (parts.length != 3) return SizedBox.shrink();

        final task = parts[0];
        final person = parts[1];
        final due = parts[2];

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: false,
                onChanged: (_) {}, // You can manage state if needed
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        )),
                    const SizedBox(height: 4),
                    Text(
                      "$person · Due: $due",
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTranscriptTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transcript.length,
      itemBuilder: (context, index) {
        final entry = transcript[index];
        return _buildTranscriptMessage(
          entry['speaker'] ?? 'Unknown',
          entry['text'] ?? '',
          '${entry['start'].toStringAsFixed(2)}s - ${entry['end'].toStringAsFixed(2)}s',
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sample Analytics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                      value: 40,
                      title: 'S1\n40%',
                      color: Colors.blue,
                      radius: 80),
                  PieChartSectionData(
                      value: 30,
                      title: 'S2\n30%',
                      color: Colors.green,
                      radius: 80),
                  PieChartSectionData(
                      value: 20,
                      title: 'S3\n20%',
                      color: Colors.orange,
                      radius: 80),
                  PieChartSectionData(
                      value: 10,
                      title: 'Others\n10%',
                      color: Colors.purple,
                      radius: 80),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptMessage(
      String speaker, String message, String timeRange) {
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
                Text(speaker,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.blue)),
                Text(timeRange,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
