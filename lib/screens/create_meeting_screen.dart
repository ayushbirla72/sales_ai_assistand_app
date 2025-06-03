import 'package:flutter/material.dart';
import '../services/meeting_service.dart';
import '../config/app_config.dart';
import 'package:intl/intl.dart';
import 'home_screen.dart';

class CreateMeetingScreen extends StatefulWidget {
  final Map<String, dynamic>? existingMeeting;
  final VoidCallback? onMeetingCreated;

  const CreateMeetingScreen({
    super.key,
    this.existingMeeting,
    this.onMeetingCreated,
  });

  @override
  _CreateMeetingScreenState createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _detailsController;
  late final TextEditingController _productDetailsController;
  late final TextEditingController _topicsController;
  late final TextEditingController _participantsController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isLoading = false;
  final _meetingService = MeetingService();

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.existingMeeting?['title']);
    _detailsController = TextEditingController();
    _productDetailsController = TextEditingController();
    _topicsController = TextEditingController();
    _participantsController = TextEditingController();

    // Parse existing date and time if available
    if (widget.existingMeeting?['startTime'] != null) {
      final timeStr = widget.existingMeeting!['startTime'];
      final timeFormat = DateFormat('hh:mm a');
      final time = timeFormat.parse(timeStr);
      _selectedTime = TimeOfDay(hour: time.hour, minute: time.minute);
    } else {
      _selectedTime = TimeOfDay.now();
    }

    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    _productDetailsController.dispose();
    _topicsController.dispose();
    _participantsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _createMeeting() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Combine date and time
      final scheduledTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Split topics by comma and trim whitespace
      final topics = _topicsController.text
          .split(',')
          .map((topic) => topic.trim())
          .where((topic) => topic.isNotEmpty)
          .toList();

      // Parse number of participants
      final numberOfParticipants = int.parse(_participantsController.text);

      // Get the event ID from the existing meeting
      final eventId = widget.existingMeeting?['eventId'];

      // Create meeting with event ID if it exists
      await _meetingService.createMeeting(
        title: _titleController.text,
        details: _detailsController.text,
        productDetails: _productDetailsController.text,
        topics: topics,
        scheduledTime: scheduledTime,
        numberOfParticipants: numberOfParticipants,
        eventId: eventId, // Pass the event ID from Google Calendar
      );

      if (mounted) {
        // Call the callback to refresh meetings if provided
        widget.onMeetingCreated?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meeting details uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to previous screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading meeting details: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Meeting'),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Meeting Title
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Meeting Title',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a meeting title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Number of Participants
                  TextFormField(
                    controller: _participantsController,
                    decoration: const InputDecoration(
                      labelText: 'Number of Participants',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.people),
                      hintText: 'Enter expected number of participants',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter number of participants';
                      }
                      final number = int.tryParse(value);
                      if (number == null) {
                        return 'Please enter a valid number';
                      }
                      if (number < AppConfig.minParticipants) {
                        return 'Minimum ${AppConfig.minParticipants} participants required';
                      }
                      if (number > AppConfig.maxParticipants) {
                        return 'Maximum ${AppConfig.maxParticipants} participants allowed';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Meeting Details
                  TextFormField(
                    controller: _detailsController,
                    decoration: const InputDecoration(
                      labelText: 'Meeting Details',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter meeting details';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Product Details
                  TextFormField(
                    controller: _productDetailsController,
                    decoration: const InputDecoration(
                      labelText: 'Product Details',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inventory),
                    ),
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter product details';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Topics
                  TextFormField(
                    controller: _topicsController,
                    decoration: const InputDecoration(
                      labelText: 'Topics to Discuss',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.topic),
                      hintText: 'Enter topics separated by commas',
                    ),
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter topics to discuss';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date and Time Selection - Only show if no existing meeting
                  if (widget.existingMeeting == null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Meeting Date & Time',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _selectDate(context),
                                    icon: const Icon(Icons.calendar_today),
                                    label: Text(
                                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _selectTime(context),
                                    icon: const Icon(Icons.access_time),
                                    label: Text(_selectedTime.format(context)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Submit Button
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _createMeeting,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.add_circle),
                    label: Text(_isLoading ? 'Creating...' : 'Create Meeting'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
