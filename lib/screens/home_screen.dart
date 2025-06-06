import 'package:flutter/material.dart';
import 'meeting_history_screen.dart';
import 'create_meeting_screen.dart';
import 'voice_samples_screen.dart';
import 'settings_screen.dart';
import 'meeting_details_screen.dart';
import 'live_suggestions_screen.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/meeting_service.dart';
import '../services/calendar_sync_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'meeting_interface_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late AuthService _authService;

  @override
  void initState() {
    super.initState();
    _initializeAuthService();
  }

  Future<void> _initializeAuthService() async {
    final prefs = await SharedPreferences.getInstance();
    _authService = AuthService(prefs: prefs);
  }

  final List<Widget> _screens = [
    const HomeContent(),
    const CreateMeetingScreen(),
    const VoiceSamplesScreen(),
  ];

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: const Text('John Doe'),
                subtitle: const Text('john.doe@example.com'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to profile page
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutConfirmation(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _handleLogout();
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Create',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Voice'),
        ],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  List<dynamic> todayMeetings = [];
  List<dynamic> liveMeetings = [];
  List<dynamic> completedMeetings = [];
  bool isLoading = false;
  bool isLoadingLiveMeetings = false;
  bool isLoadingCompletedMeetings = false;
  final MeetingService meetingService = MeetingService();
  final CalendarSyncService calendarSyncService =
      CalendarSyncService(GoogleSignIn());

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      fetchTodayMeetings(),
      fetchLiveMeetings(),
      fetchCompletedMeetings(),
    ]);
  }

  Future<void> fetchTodayMeetings() async {
    setState(() => isLoading = true);
    try {
      final meetings = await calendarSyncService.fetchGoogleCalendarEvents();
      setState(() {
        todayMeetings = meetings;
      });
    } catch (e) {
      // Handle error
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchLiveMeetings() async {
    setState(() => isLoadingLiveMeetings = true);
    try {
      final meetings = await calendarSyncService.fetchLiveMeetings();
      setState(() {
        liveMeetings = meetings;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching live meetings: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => isLoadingLiveMeetings = false);
    }
  }

  Future<void> fetchCompletedMeetings() async {
    setState(() => isLoadingCompletedMeetings = true);
    try {
      final meetings = await calendarSyncService.fetchCompletedMeetings();
      setState(() {
        completedMeetings = meetings;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching completed meetings: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => isLoadingCompletedMeetings = false);
    }
  }

  void _showJoinZoomDialog(BuildContext context) {
    final TextEditingController meetingLinkController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Join Zoom Meeting'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: meetingLinkController,
                decoration: const InputDecoration(
                  hintText: 'Enter Zoom meeting link',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.video_camera_front),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              const Text(
                'Please enter the complete meeting link including https://',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                meetingLinkController.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (meetingLinkController.text.isNotEmpty) {
                  // TODO: Implement meeting joining logic
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Joining Zoom meeting...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Join'),
            ),
          ],
        );
      },
    );
  }

  void _showJoinGoogleMeetDialog(BuildContext context) {
    final TextEditingController meetingLinkController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Join Google Meet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: meetingLinkController,
                decoration: const InputDecoration(
                  hintText: 'Enter Google Meet link',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.video_call),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              const Text(
                'Please enter the complete meeting link including https://',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                meetingLinkController.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (meetingLinkController.text.isNotEmpty) {
                  // TODO: Implement meeting joining logic
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Joining Google Meet...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Join'),
            ),
          ],
        );
      },
    );
  }

  void _showUploadDetailsDialog(
      BuildContext context, Map<String, dynamic> meeting) {
    final TextEditingController titleController =
        TextEditingController(text: meeting['title']);
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController productDetailsController =
        TextEditingController();
    final TextEditingController participantsController =
        TextEditingController();
    final TextEditingController topicsController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Upload Meeting Details'),
                backgroundColor: Colors.orange,
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      // TODO: Implement upload functionality
                      final meetingDetails = {
                        'title': titleController.text,
                        'description': descriptionController.text,
                        'productDetails': productDetailsController.text,
                        'participants':
                            int.tryParse(participantsController.text) ?? 0,
                        'topics': topicsController.text
                            .split(',')
                            .map((e) => e.trim())
                            .toList(),
                      };
                      print('Uploading meeting details: $meetingDetails');
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Meeting details uploaded successfully'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Text(
                      'Upload',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Meeting Title',
                        border: OutlineInputBorder(),
                      ),
                      enabled:
                          meeting['title'] == null || meeting['title'].isEmpty,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: productDetailsController,
                      decoration: const InputDecoration(
                        labelText: 'Product Details',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: participantsController,
                      decoration: const InputDecoration(
                        labelText: 'Number of Participants',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: topicsController,
                      decoration: const InputDecoration(
                        labelText: 'Topics (comma separated)',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., Product Demo, Q&A, Pricing',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              final _HomeScreenState? state =
                  context.findAncestorStateOfType<_HomeScreenState>();
              if (state != null) {
                state._showProfileMenu(context);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Live Meetings Section
              const Text(
                'Live Meetings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.video_camera_front,
                              color: Colors.red),
                          const SizedBox(width: 8),
                          const Text(
                            'Active Now',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
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
                      const SizedBox(height: 16),
                      isLoadingLiveMeetings
                          ? const Center(child: CircularProgressIndicator())
                          : liveMeetings.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text(
                                      'No live meetings at the moment',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: liveMeetings.length,
                                  itemBuilder: (context, index) {
                                    final meeting = liveMeetings[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor:
                                              Colors.blue.withOpacity(0.1),
                                          child: const Icon(
                                            Icons.groups,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        title: Text(meeting['title'] ??
                                            'Untitled Meeting'),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Started: ${meeting['startTime']}',
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            ),
                                            if (meeting['duration'].isNotEmpty)
                                              Text(
                                                'Duration: ${meeting['duration']}',
                                                style: const TextStyle(
                                                    fontSize: 12),
                                              ),
                                            if (meeting['creator'].isNotEmpty)
                                              Text(
                                                'Created by: ${meeting['creator']}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (meeting['status'] ==
                                                'confirmed')
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Text(
                                                  'Live',
                                                  style: TextStyle(
                                                    color: Colors.green,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(width: 8),
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        LiveSuggestionsScreen(
                                                      meetingTitle: meeting[
                                                              'title'] ??
                                                          'Untitled Meeting',
                                                      meetingDuration:
                                                          meeting['duration'],
                                                      participantCount:
                                                          0, // TODO: Add participant count if available
                                                    ),
                                                  ),
                                                );
                                              },
                                              icon: const Icon(Icons.insights),
                                              label: const Text('Show'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Scheduled Meetings Section
              const Text(
                'Scheduled Meetings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'Today\'s Meetings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: fetchTodayMeetings,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: todayMeetings.length,
                              itemBuilder: (context, index) {
                                final meeting = todayMeetings[index];
                                return StatefulBuilder(
                                  builder: (context, setState) {
                                    bool isEnabled = true;
                                    return ListTile(
                                      leading: const CircleAvatar(
                                        backgroundColor: Colors.blue,
                                        child: Icon(Icons.event,
                                            color: Colors.white),
                                      ),
                                      title: Text(meeting['title'] ??
                                          'Meeting ${index + 1}'),
                                      subtitle: Text(
                                        '${meeting['startTime']} - ${meeting['endTime']}',
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (meeting['mode'] == 'Offline')
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        MeetingInterfaceScreen(
                                                      meetingTitle: meeting[
                                                              'title'] ??
                                                          'Untitled Meeting',
                                                      meetingId: meeting[
                                                              'meetingId'] ??
                                                          '',
                                                      eventId:
                                                          meeting['eventId'] ??
                                                              '',
                                                      isOffline: true,
                                                    ),
                                                  ),
                                                );
                                              },
                                              icon:
                                                  const Icon(Icons.play_arrow),
                                              label: const Text('Start'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                              ),
                                            )
                                          else if (meeting[
                                                  'isMeetingDetailsUploaded'] ==
                                              true)
                                            Row(
                                              children: [
                                                Text(
                                                  'Auto Join',
                                                  style: TextStyle(
                                                    color: isEnabled
                                                        ? Colors.green
                                                        : Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Switch(
                                                  value: isEnabled,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      isEnabled = value;
                                                    });
                                                    if (value) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                              'Auto-join enabled for ${meeting['title']}'),
                                                          duration:
                                                              const Duration(
                                                                  seconds: 2),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  activeColor: Colors.green,
                                                ),
                                              ],
                                            )
                                          else
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        CreateMeetingScreen(
                                                      existingMeeting: meeting,
                                                      onMeetingCreated:
                                                          fetchTodayMeetings,
                                                    ),
                                                  ),
                                                );
                                              },
                                              icon:
                                                  const Icon(Icons.upload_file),
                                              label: const Text('Upload'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.orange,
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quick Join Section
              // const Text(
              //   'Quick Join',
              //   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              // ),
              // const SizedBox(height: 16),
              // Card(
              //   child: Padding(
              //     padding: const EdgeInsets.all(16),
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.stretch,
              //       children: [
              //         ElevatedButton.icon(
              //           onPressed: () => _showJoinZoomDialog(context),
              //           icon: const Icon(Icons.video_camera_front),
              //           label: const Text('Join Zoom Meeting'),
              //           style: ElevatedButton.styleFrom(
              //             padding: const EdgeInsets.symmetric(vertical: 16),
              //             backgroundColor: Colors.blue,
              //           ),
              //         ),
              //         const SizedBox(height: 12),
              //         ElevatedButton.icon(
              //           onPressed: () => _showJoinGoogleMeetDialog(context),
              //           icon: const Icon(Icons.video_camera_front),
              //           label: const Text('Join Google Meet'),
              //           style: ElevatedButton.styleFrom(
              //             padding: const EdgeInsets.symmetric(vertical: 16),
              //             backgroundColor: Colors.red,
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),

              const SizedBox(height: 24),

              // Recent Meetings Section
              const Text(
                'Recent Meetings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              isLoadingCompletedMeetings
                  ? const Center(child: CircularProgressIndicator())
                  : completedMeetings.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No recent meetings',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: completedMeetings.length,
                          itemBuilder: (context, index) {
                            final meeting = completedMeetings[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.blue,
                                  child: Icon(Icons.meeting_room,
                                      color: Colors.white),
                                ),
                                title: Text(
                                    meeting['title'] ?? 'Untitled Meeting'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Date: ${meeting['date']}'),
                                    Text(
                                      'Time: ${meeting['startTime']} - ${meeting['endTime']}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    if (meeting['duration']?.isNotEmpty ??
                                        false)
                                      Text(
                                        'Duration: ${meeting['duration']}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    if (meeting['creator']?.isNotEmpty ?? false)
                                      Text(
                                        'Created by: ${meeting['creator']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Get the status and corresponding style
                                    if (meeting['status'] != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color:
                                              _getStatusColor(meeting['status'])
                                                  .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _getStatusLabel(meeting['status']),
                                          style: TextStyle(
                                            color: _getStatusColor(
                                                meeting['status']),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward_ios,
                                        size: 16),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          MeetingDetailsScreen(
                                        meetingTitle: meeting['title'] ??
                                            'Untitled Meeting',
                                        meetingDate: meeting['date'] ?? '',
                                        meetingId: meeting['meetingId'] ?? '',
                                        eventId: meeting['eventId'] ?? '',
                                        userId: meeting['userId'] ?? '',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'confirmed':
        return Colors.orange;
      case 'start':
        return Colors.orange;
      case 'progress':
        return Colors.amber;
      case 'transcription':
        return Colors.purple;
      case 'cancelled':
        return Colors.red;
      case 'failed':
        return Colors.redAccent;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return 'Scheduled';
      case 'start':
        return 'Started';
      case 'progress':
        return 'In Progress';
      case 'transcription':
        return 'Transcription';
      case 'cancelled':
        return 'Cancelled';
      case 'failed':
        return 'Failed';
      case 'completed':
        return 'Completed';
      case 'confirmed':
        return 'Confirmed';
      default:
        return 'Unknown';
    }
  }
}
