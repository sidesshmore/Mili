import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mindmate/constants.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';

class MicInput extends StatefulWidget {
  final Function(String) onTranscription;

  const MicInput({super.key, required this.onTranscription});

  @override
  State<MicInput> createState() => _MicInputState();
}

class _MicInputState extends State<MicInput> with TickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isInitialized = false;
  String _recordingPath = '';
  String? _deepgramApiKey;
  Deepgram? _deepgram;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeDeepgram();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeDeepgram() async {
    try {
      final permissionGranted = await _checkAndRequestPermission();
      if (!permissionGranted) {
        setState(() => _isInitialized = true);
        return;
      }

      _deepgramApiKey = dotenv.env['DEEPGRAM_API_KEY'];
      if (_deepgramApiKey == null || _deepgramApiKey!.isEmpty) {
        throw Exception('DEEPGRAM_API_KEY not found in .env file');
      }

      // Initialize Deepgram
      _deepgram = Deepgram(_deepgramApiKey!);

      setState(() => _isInitialized = true);
      log('Deepgram initialized successfully');
    } catch (e) {
      log('Error initializing Deepgram: $e');
      setState(() => _isInitialized = true);
      _showErrorMessage('Failed to initialize speech recognition: $e');
    }
  }

  Future<bool> _checkAndRequestPermission() async {
    try {
      final status = await Permission.microphone.status;

      if (status.isGranted) return true;

      if (status.isDenied) {
        final result = await Permission.microphone.request();
        if (result.isGranted) {
          return true;
        } else if (result.isPermanentlyDenied) {
          _showSettingsDialog();
          return false;
        } else {
          _showPermissionDialog();
          return false;
        }
      }

      if (status.isPermanentlyDenied) {
        _showSettingsDialog();
        return false;
      }

      return false;
    } catch (e) {
      log('Error checking microphone permission: $e');
      _showErrorMessage('Permission error: $e');
      return false;
    }
  }

  Future<void> _handleMicTap() async {
    if (_isProcessing || !_isInitialized) return;

    final hasPermission = await _checkAndRequestPermission();
    if (!hasPermission) return;

    try {
      if (!_isRecording) {
        await _startRecording();
      } else {
        await _stopRecording();
      }
    } catch (e) {
      log('Error in handleMicTap: $e');
      _showErrorMessage('Microphone error: $e');
      setState(() {
        _isRecording = false;
        _isProcessing = false;
      });
      _stopAnimations();
    }
  }

  Future<void> _startRecording() async {
    try {
      setState(() {
        _isRecording = true;
        _isProcessing = false;
      });

      _startAnimations();

      if (!await _audioRecorder.hasPermission()) {
        throw Exception('Audio recording permission denied');
      }

      final Directory appDir = await getApplicationDocumentsDirectory();
      _recordingPath =
          '${appDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

      final config = RecordConfig(
        encoder: AudioEncoder.wav,
        bitRate: 128000,
        sampleRate: 16000,
        numChannels: 1,
      );

      await _audioRecorder.start(config, path: _recordingPath);
      log('Recording started: $_recordingPath');
    } catch (e) {
      log('Error starting recording: $e');
      _showErrorMessage('Failed to start recording: $e');
      setState(() {
        _isRecording = false;
        _isProcessing = false;
      });
      _stopAnimations();
    }
  }

  Future<void> _stopRecording() async {
    try {
      setState(() {
        _isRecording = false;
        _isProcessing = true;
      });

      _stopAnimations();

      final path = await _audioRecorder.stop();
      log('Recording stopped: $path');

      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          await _transcribeAudioWithDeepgram(file);
        } else {
          throw Exception('Recording file not found');
        }
      } else {
        throw Exception('No recording path received');
      }
    } catch (e) {
      log('Error stopping recording: $e');
      _showErrorMessage('Failed to stop recording: $e');
    } finally {
      setState(() {
        _isRecording = false;
        _isProcessing = false;
      });
    }
  }

  Future<void> _transcribeAudioWithDeepgram(File audioFile) async {
    try {
      log('Starting Deepgram transcription: ${audioFile.path}');

      if (_deepgram == null) {
        throw Exception('Deepgram not initialized');
      }

      // Use the correct Deepgram API method with query parameters
      final result = await _deepgram!.listen.file(
        audioFile,
        queryParams: {
          'model': 'nova-2-general',
          'detect_language': true,
          'punctuation': true,
          'filler_words': false,
        },
      );

      log('Deepgram response received');
      log('Transcript: ${result.transcript}');

      if (result.transcript != null && result.transcript!.trim().isNotEmpty) {
        widget.onTranscription(result.transcript!);
      } else {
        log('Empty transcript from Deepgram');
        _showErrorMessage('No speech detected in the recording');
      }

      // Clean up audio file
      try {
        await audioFile.delete();
        log('Audio file deleted: ${audioFile.path}');
      } catch (e) {
        log('Failed to delete audio file: $e');
      }
    } catch (e) {
      log('Deepgram transcription error: $e');
      _showErrorMessage('Failed to transcribe audio: $e');
    }
  }

  void _startAnimations() {
    _animationController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
  }

  void _stopAnimations() {
    _animationController.stop();
    _animationController.reset();
    _pulseController.stop();
    _pulseController.reset();
  }

  void _showPermissionDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Microphone Permission Required'),
        content: const Text(
          'MindMate needs microphone access for voice input. Please grant permission to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await Permission.microphone.request();
              if (result.isGranted) _initializeDeepgram();
            },
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Microphone access has been permanently denied. Please enable it in device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Color _getMicButtonColor() {
    if (_isRecording) return Colors.red.shade400;
    if (_isProcessing) return Colors.orange.shade400;
    if (!_isInitialized) return Colors.grey.shade400;
    return Globals.customBlue;
  }

  IconData _getMicIcon() {
    if (_isRecording) return Icons.stop_circle_outlined;
    if (_isProcessing) return Icons.hourglass_bottom_rounded;
    if (!_isInitialized) return Icons.mic_off_rounded;
    return Icons.mic_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isInitialized ? _handleMicTap : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _pulseAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _isRecording
                ? _scaleAnimation.value
                : (_isProcessing ? _pulseAnimation.value : 1.0),
            child: Container(
              width: Globals.screenWidth * 0.12,
              height: Globals.screenWidth * 0.12,
              decoration: BoxDecoration(
                color: _getMicButtonColor(),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _getMicButtonColor().withOpacity(0.3),
                    spreadRadius: _isRecording ? 3 : 1,
                    blurRadius: _isRecording ? 10 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _getMicIcon(),
                color: Colors.white,
                size: Globals.screenWidth * 0.06,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }
}
