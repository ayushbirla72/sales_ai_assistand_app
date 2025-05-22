import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:salse_ai_assistant/services/base_api_service.dart';
import '../services/file_upload_service.dart';

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
  String? _recordingPath;
  final _audioRecorder = AudioRecorder();
  late final AudioPlayer _audioPlayer;
  final String _sampleText = '''
Hello! I'm excited to tell you about our latest product. It's designed to help businesses like yours increase efficiency and reduce costs. Our solution offers:

1. Advanced automation features
2. Real-time analytics and reporting
3. Seamless integration with existing systems
4. 24/7 customer support
5. Regular updates and improvements

Would you like to learn more about how we can help your business grow?
''';
  final _fileUploadService = FileUploadService();
  bool _isUploading = false;
  String? _uploadedFileId;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    final hasPermission = await _requestMicrophonePermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is required to record audio'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<String> _getRecordingPath() async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${directory.path}/recording_$timestamp.m4a';
  }

  Future<void> _startRecording() async {
    try {
      if (await Permission.microphone.isGranted) {
        _recordingPath = await _getRecordingPath();
        await _audioRecorder.start(
          RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: _recordingPath!,
        );

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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting recording: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stop();
      _timer?.cancel();

      setState(() {
        _isRecording = false;
        _hasRecording = true;
      });

      // Upload the recording
      await _uploadRecording();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error stopping recording: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadRecording() async {
    if (_recordingPath == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final file = File(_recordingPath!);
      if (!await file.exists()) {
        throw Exception('Recording file not found');
      }

      final response = await _fileUploadService.uploadSalespersonAudio(
        file: file,
        fileType: 'voice_sample',
        metadata: {
          'duration': _recordingDuration,
          'sample_type': 'sales_pitch',
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      _uploadedFileId = response['file_id'];

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice sample uploaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      print('Error uploading voice sample: $e');
      final errorMessage =
          e is ApiException ? e.message : 'An unexpected error occurred';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading voice sample: $errorMessage'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _playRecording() async {
    try {
      if (_recordingPath != null) {
        await _audioPlayer.setFilePath(_recordingPath!);
        await _audioPlayer.play();

        setState(() {
          _isPlaying = true;
        });

        _audioPlayer.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            setState(() {
              _isPlaying = false;
            });
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing recording: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error pausing recording: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteRecording() async {
    try {
      if (_uploadedFileId != null) {
        await _fileUploadService.deleteFile(_uploadedFileId!);
      }

      if (_recordingPath != null) {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      setState(() {
        _hasRecording = false;
        _recordingPath = null;
        _uploadedFileId = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting recording: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteRecording();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
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
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Samples'),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          Padding(
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
                                    'Duration: ${_formatDuration(_recordingDuration)}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.play_arrow),
                                    onPressed: _isUploading
                                        ? null
                                        : _showPlayAudioDialog,
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: _isUploading
                                        ? null
                                        : _showDeleteConfirmation,
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
                    onPressed: _isUploading ? null : _startRecording,
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
                                const Icon(Icons.mic,
                                    color: Colors.red, size: 30),
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
                            onPressed: _isUploading
                                ? null
                                : (_isRecording
                                    ? _stopRecording
                                    : _startRecording),
                            icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                            label: Text(
                              _isRecording
                                  ? 'Stop Recording'
                                  : 'Start Recording',
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
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Uploading voice sample...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
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
}
