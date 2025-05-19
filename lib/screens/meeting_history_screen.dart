import 'package:flutter/material.dart';

class MeetingHistoryScreen extends StatefulWidget {
  const MeetingHistoryScreen({super.key});

  @override
  _MeetingHistoryScreenState createState() => _MeetingHistoryScreenState();
}

class _MeetingHistoryScreenState extends State<MeetingHistoryScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'This Week', 'This Month', 'This Year'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meeting History'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children:
                    _filters.map((filter) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: _selectedFilter == filter,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                          backgroundColor: Colors.grey[200],
                          selectedColor: Colors.blue[100],
                          checkmarkColor: Colors.blue,
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),

          // Meeting List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 20, // Sample data
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(index),
                      child: Icon(_getStatusIcon(index), color: Colors.white),
                    ),
                    title: Text('Meeting ${index + 1}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date: ${DateTime.now().subtract(Duration(days: index)).toString().split(' ')[0]}',
                        ),
                        Text('Duration: ${(index + 1) * 30} minutes'),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Meeting Details',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This was a meeting about product ${index + 1} with client ${index + 1}. '
                              'The discussion covered various topics including pricing, features, and implementation timeline.',
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () {
                                    // TODO: View recording
                                  },
                                  icon: const Icon(Icons.play_circle_outline),
                                  label: const Text('View Recording'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    // TODO: View transcript
                                  },
                                  icon: const Icon(Icons.description),
                                  label: const Text('View Transcript'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(int index) {
    // Sample logic for status colors
    switch (index % 4) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.red;
      case 3:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(int index) {
    // Sample logic for status icons
    switch (index % 4) {
      case 0:
        return Icons.check;
      case 1:
        return Icons.pending;
      case 2:
        return Icons.cancel;
      case 3:
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }
}
