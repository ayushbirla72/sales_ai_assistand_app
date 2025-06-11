import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/audio_api_service.dart';

class MeetingInterfaceScreen extends StatefulWidget {
  final String meetingTitle;
  final bool isOffline;
  final String meetingId;
  final String eventId;

  const MeetingInterfaceScreen({
    Key? key,
    required this.meetingTitle,
    required this.meetingId,
    required this.eventId,
    this.isOffline = false,
  }) : super(key: key);

  @override
  _MeetingInterfaceScreenState createState() => _MeetingInterfaceScreenState();
}

class _MeetingInterfaceScreenState extends State<MeetingInterfaceScreen>
    with SingleTickerProviderStateMixin {
  bool isRecording = false;
  late AnimationController _animationController;
  final List<double> _waveHeights = List.generate(30, (index) => 0.0);
  final List<Map<String, dynamic>> _transcript = [];
  final List<Map<String, dynamic>> _suggestions = [];
  final ScrollController _transcriptController = ScrollController();
  final ScrollController _suggestionsController = ScrollController();
  Timer? _waveTimer;
  Timer? _suggestionTimer;
  Timer? _chunkTimer;

  // Audio recording
  // final _audioRecorder = AudioRecorder();
  final AudioRecorder _fullRecorder = AudioRecorder(); // For full session
  final AudioRecorder _chunkRecorder = AudioRecorder(); // For 10-sec chunks

  final Set<String> _seenChunkNames = {};

  String? _recordingPath;
  Timer? _amplitudeTimer;
  double _currentAmplitude = 0.0;
  final _audioApiService = AudioApiService();
  String? _currentChunkPath;
  String? _completeRecordingPath;
  int _chunkCounter = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    // Simulate live transcript updates
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!isRecording) return;

      try {
        final chunks =
            await _audioApiService.getTranscript(); // returns List<dynamic>

        if (chunks != null && chunks.isNotEmpty) {
          setState(() {
            for (final chunk in chunks) {
              final chunkName = chunk['chunk_name']?.toString();
              final transcript = chunk['transcript']?.toString();

              if (chunkName != null &&
                  !_seenChunkNames.contains(chunkName) &&
                  transcript != null &&
                  transcript.isNotEmpty) {
                _transcript.add({
                  'type': 'transcript',
                  'message': transcript,
                  'time': DateTime.now(),
                });

                _seenChunkNames.add(chunkName);
              }
            }

            _scrollToBottom(_transcriptController);
          });
        }
      } catch (e) {
        print('Error fetching transcript: $e');
      }
    });

    Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (isRecording) {
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
      }
    });
  }

  Future<void> _requestPermissions() async {
    final micStatus = await Permission.microphone.request();
    if (micStatus != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required for recording'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
  }

  Future<void> _startNewChunk() async {
    try {
      final directory = await getTemporaryDirectory();
      _currentChunkPath = '${directory.path}/chunk_${_chunkCounter++}.wav';

      await _chunkRecorder.start(
        RecordConfig(
          encoder: AudioEncoder.wav,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: _currentChunkPath!,
      );

      print('Started new chunk at path: $_currentChunkPath');
    } catch (e) {
      print('Error starting new chunk: $e');
      rethrow;
    }
  }

  Future<void> _processChunk() async {
    if (_currentChunkPath != null) {
      try {
        final chunkFile = File(_currentChunkPath!);
        if (await chunkFile.exists()) {
          print('Processing chunk at path: $_currentChunkPath');
          var response = await _audioApiService.sendAudioChunk(chunkFile);

          // setState(() {
          //   _transcript.add({
          //     'type': 'bot',
          //     'message': response['transcript'] ?? "",
          //     'time': DateTime.now(),
          //   });
          // });

          // _scrollToBottom(_transcriptController);

          await chunkFile.delete(); // Clean up the chunk file
          print('Chunk processed and deleted successfully');
        } else {
          print('Chunk file not found at path: $_currentChunkPath');
        }
      } catch (e) {
        print('Error processing chunk: $e');
        rethrow;
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      await _requestPermissions();

      // Create path for complete recording
      final directory = await getTemporaryDirectory();
      _completeRecordingPath = '${directory.path}/complete_recording.wav';

      // Start the complete recording
      await _fullRecorder.start(
        RecordConfig(
          encoder: AudioEncoder.wav,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: _completeRecordingPath!,
      );

      await _audioApiService.startStreaming(widget.meetingId, widget.eventId);
      await _startNewChunk();

      // Start chunk timer (10 seconds)
      _chunkTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
        if (isRecording) {
          await _chunkRecorder.stop();
          await _processChunk();
          await _startNewChunk();
        }
      });

      // Start amplitude monitoring
      _amplitudeTimer =
          Timer.periodic(const Duration(milliseconds: 100), (timer) async {
        if (await _chunkRecorder.isRecording()) {
          final amplitude = await _chunkRecorder.getAmplitude();
          setState(() {
            _currentAmplitude = amplitude.current.abs() / 32768.0;
            for (int i = 0; i < _waveHeights.length; i++) {
              _waveHeights[i] = _currentAmplitude *
                  50 *
                  (0.5 + math.Random().nextDouble() * 0.5);
            }
          });
        }
      });

      setState(() {
        isRecording = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting recording: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      // Cancel all timers first
      _chunkTimer?.cancel();
      _amplitudeTimer?.cancel();

      // Stop the audio recorder
      if (await _fullRecorder.isRecording()) {
        await _fullRecorder.stop();
      }

      if (await _chunkRecorder.isRecording()) {
        await _chunkRecorder.stop();
      }

      // Process the final chunk if it exists
      if (_currentChunkPath != null) {
        await _processChunk();
      }

      // Stop streaming
      _audioApiService.stopStreaming();

      // Reset state
      if (mounted) {
        setState(() {
          isRecording = false;
          _currentAmplitude = 0.0;
          for (int i = 0; i < _waveHeights.length; i++) {
            _waveHeights[i] = 0;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording stopped'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error stopping recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error stopping recording: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _completeMeeting() async {
    try {
      // First stop recording if it's still active
      if (isRecording) {
        await _stopRecording();
      }

      // Ensure we have valid IDs
      if (widget.meetingId.isEmpty || widget.eventId.isEmpty) {
        throw Exception('Missing meetingId or eventId');
      }

      print(
          'Completing meeting with ID: ${widget.meetingId} and event ID: ${widget.eventId}');

      // Send the complete recording
      if (_completeRecordingPath != null) {
        final completeFile = File(_completeRecordingPath!);
        if (await completeFile.exists()) {
          print('Sending complete recording from: $_completeRecordingPath');
          final result = await _audioApiService.sendCompleteAudio(completeFile);
          print('Meeting completion result: $result');

          // Clean up
          await completeFile.delete();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Meeting completed successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('Complete recording file not found');
        }
      } else {
        throw Exception('No complete recording path available');
      }
    } catch (e) {
      print('Error completing meeting: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing meeting: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
  void dispose() {
    _chunkRecorder.dispose();
    _fullRecorder.dispose();
    _amplitudeTimer?.cancel();
    _chunkTimer?.cancel();
    _animationController.dispose();
    _waveTimer?.cancel();
    _suggestionTimer?.cancel();
    _transcriptController.dispose();
    _suggestionsController.dispose();
    _audioApiService.dispose();
    super.dispose();
  }

  Widget _buildBubble(Map<String, dynamic> item) {
    final Color bubbleColor;
    final IconData icon;
    final Color iconColor;

    switch (item['type']) {
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
      case 'transcript':
        bubbleColor = Colors.grey.withOpacity(0.1);
        icon = Icons.mic;
        iconColor = Colors.grey;
        break;
      default:
        bubbleColor = Colors.grey.withOpacity(0.1);
        icon = Icons.info;
        iconColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['message'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(item['time']),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(
          widget.meetingTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show meeting options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isRecording
                        ? Colors.red.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isRecording ? Icons.fiber_manual_record : Icons.circle,
                        color: isRecording ? Colors.red : Colors.grey,
                        size: 12,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isRecording ? 'Recording' : 'Ready',
                        style: TextStyle(
                          color: isRecording ? Colors.red : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (widget.isOffline)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_off,
                          color: Colors.orange,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Offline Mode',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Audio Wave Animation
          Container(
            height: 120,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _waveHeights.map((height) {
                return Container(
                  width: 3,
                  height: height,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isRecording
                        ? const Color(0xFF4A90E2)
                        : Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }).toList(),
            ),
          ),
          // Live Transcript
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.transcribe,
                          color: Color(0xFF4A90E2),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Live Transcript',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const Spacer(),
                        if (_transcript.isNotEmpty)
                          TextButton.icon(
                            onPressed: () {
                              // TODO: Implement transcript actions
                            },
                            icon: const Icon(Icons.more_horiz),
                            label: const Text('Actions'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF4A90E2),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: _transcriptController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _transcript.length,
                      itemBuilder: (context, index) {
                        return _buildBubble(_transcript[index]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Suggestions
          Expanded(
            child: Container(
              height: 120,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          color: Color(0xFFFFB74D),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Suggestions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const Spacer(),
                        if (_suggestions.isNotEmpty)
                          TextButton.icon(
                            onPressed: () {
                              // TODO: Implement suggestion actions
                            },
                            icon: const Icon(Icons.more_horiz),
                            label: const Text('Actions'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF4A90E2),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: _suggestionsController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        return _buildBubble(_suggestions[index]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Control Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isRecording)
                  ElevatedButton.icon(
                    onPressed: _startRecording,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Recording'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ElevatedButton.icon(
                      //   onPressed: () async {
                      //     // await _stopRecording();
                      //   },
                      //   icon: const Icon(Icons.stop),
                      //   label: const Text('Stop'),
                      //   style: ElevatedButton.styleFrom(
                      //     backgroundColor: Colors.red,
                      //     foregroundColor: Colors.white,
                      //     padding: const EdgeInsets.symmetric(
                      //       horizontal: 32,
                      //       vertical: 16,
                      //     ),
                      //     shape: RoundedRectangleBorder(
                      //       borderRadius: BorderRadius.circular(12),
                      //     ),
                      //   ),
                      // ),
                      // const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final shouldComplete = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Complete Meeting'),
                              content: const Text(
                                  'Are you sure you want to complete this meeting?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4CAF50),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Complete'),
                                ),
                              ],
                            ),
                          );

                          if (shouldComplete == true && mounted) {
                            await _completeMeeting();
                            if (mounted) {
                              Navigator.pop(context);
                            }
                          }
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Complete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
