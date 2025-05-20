import 'package:flutter/material.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

class VoiceSamplesScreen extends StatefulWidget {
  const VoiceSamplesScreen({super.key});

  @override
  _VoiceSamplesScreenState createState() => _VoiceSamplesScreenState();
}

class _VoiceSamplesScreenState extends State<VoiceSamplesScreen> {
  bool _isRecording = false;
  int _recordingDuration = 0;
  Timer? _timer;
  bool _hasRecording = false;
  bool _isPlaying = false;
  int _playbackPosition = 0;
  Timer? _playbackTimer;
  final String _sampleText = '''
Hello! I'm excited to tell you about our latest product. It's designed to help businesses like yours increase efficiency and reduce costs. Our solution offers:

1. Advanced automation features
2. Real-time analytics and reporting
3. Seamless integration with existing systems
4. 24/7 customer support
5. Regular updates and improvements

Would you like to learn more about how we can help your business grow?
''';

  Future<bool> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _startRecording() async {
    final hasPermission = await _requestMicrophonePermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is required to record audio'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isRecording = true;
      _recordingDuration = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration++;
      });
    });
  }

  void _stopRecording() {
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _hasRecording = true;
    });
    // TODO: Save the recording
  }

  void _showPlayAudioDialog() {
    bool dialogIsPlaying = false;
    int dialogPlaybackPosition = 0;
    Timer? dialogTimer;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Play Voice Sample'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  Icon(
                    dialogIsPlaying ? Icons.pause_circle : Icons.play_circle,
                    size: 64,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _formatDuration(dialogPlaybackPosition),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Slider(
                    value: dialogPlaybackPosition.toDouble(),
                    min: 0,
                    max: 30, // Assuming 30 seconds recording
                    onChanged: (value) {
                      setDialogState(() {
                        dialogPlaybackPosition = value.toInt();
                      });
                      // TODO: Implement seeking in audio
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.replay_10),
                        onPressed: () {
                          setDialogState(() {
                            dialogPlaybackPosition =
                                (dialogPlaybackPosition - 10).clamp(0, 30);
                          });
                          // TODO: Implement rewind
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          dialogIsPlaying ? Icons.pause : Icons.play_arrow,
                        ),
                        iconSize: 48,
                        onPressed: () {
                          setDialogState(() {
                            dialogIsPlaying = !dialogIsPlaying;
                            if (dialogIsPlaying) {
                              dialogTimer = Timer.periodic(
                                const Duration(seconds: 1),
                                (timer) {
                                  setDialogState(() {
                                    if (dialogPlaybackPosition < 30) {
                                      dialogPlaybackPosition++;
                                    } else {
                                      dialogIsPlaying = false;
                                      timer.cancel();
                                    }
                                  });
                                },
                              );
                            } else {
                              dialogTimer?.cancel();
                            }
                          });
                          // TODO: Implement actual audio playback
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.forward_10),
                        onPressed: () {
                          setDialogState(() {
                            dialogPlaybackPosition =
                                (dialogPlaybackPosition + 10).clamp(0, 30);
                          });
                          // TODO: Implement forward
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    dialogTimer?.cancel();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteConfirmation() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Voice Sample'),
          content: const Text(
            'Are you sure you want to delete this voice sample? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                _deleteRecording();
                Navigator.of(context).pop();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _deleteRecording() {
    setState(() {
      _hasRecording = false;
    });
    // TODO: Delete the actual recording file
  }

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _playbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Samples'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_hasRecording) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Your Voice Sample',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.mic, color: Colors.blue),
                              const SizedBox(width: 10),
                              Text(
                                'Duration: ${_formatDuration(30)}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.play_arrow),
                                onPressed: _showPlayAudioDialog,
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: _showDeleteConfirmation,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _startRecording,
                icon: const Icon(Icons.mic),
                label: const Text('Record New Sample'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Record Your Voice Sample',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Please read the following text:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _sampleText,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isRecording) ...[
                            const Icon(Icons.mic, color: Colors.red, size: 30),
                            const SizedBox(width: 10),
                            Text(
                              _formatDuration(_recordingDuration),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed:
                            _isRecording ? _stopRecording : _startRecording,
                        icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                        label: Text(
                          _isRecording ? 'Stop Recording' : 'Start Recording',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isRecording ? Colors.red : Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
