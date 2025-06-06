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
  String suggestion = '';
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
          suggestion = meetingData['suggestion'] as String? ?? '';

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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Text(suggestion, style: const TextStyle(fontSize: 16)),
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
