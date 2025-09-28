import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class DeepgramTTSService {
  late Deepgram _deepgram;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isDisposed = false;
  bool _isPlaying = false;
  String? _currentText;

  // Callback for when TTS completes
  Function()? _onComplete;

  DeepgramTTSService() {
    _initializeDeepgram();
  }

  Future<void> _initializeDeepgram() async {
    try {
      final apiKey = dotenv.env['DEEPGRAM_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('DEEPGRAM_API_KEY not found in .env file');
      }

      _deepgram = Deepgram(apiKey);

      // Set up audio player event handlers
      _setUpEventHandlers();

      log('Deepgram TTS initialized successfully');
    } catch (e) {
      log('Error initializing Deepgram TTS: $e');
    }
  }

  void _setUpEventHandlers() {
    try {
      _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
        switch (state) {
          case PlayerState.playing:
            _isPlaying = true;
            log('Deepgram TTS started playing');
            break;
          case PlayerState.completed:
            _isPlaying = false;
            log('Deepgram TTS completed playing');
            _onComplete?.call();
            _onComplete = null;
            break;
          case PlayerState.stopped:
            _isPlaying = false;
            log('Deepgram TTS stopped');
            _onComplete?.call();
            _onComplete = null;
            break;
          case PlayerState.paused:
            log('Deepgram TTS paused');
            break;
          case PlayerState.disposed:
            _isPlaying = false;
            break;
        }
      });

      _audioPlayer.onPlayerComplete.listen((_) {
        _isPlaying = false;
        _onComplete?.call();
        _onComplete = null;
      });
    } catch (e) {
      log('Error setting up Deepgram TTS event handlers: $e');
    }
  }

  // Convert text to speech using Deepgram and play it
  Future<bool> speakText(String text, {Function()? onComplete}) async {
    if (_isDisposed) {
      log('Deepgram TTS Service is disposed, cannot play audio');
      return false;
    }

    try {
      // Stop any current playback first
      await stopSpeaking();

      // Set completion callback
      _onComplete = onComplete;
      _currentText = text;

      log(
        'Starting Deepgram TTS for text: ${text.substring(0, text.length > 50 ? 50 : text.length)}...',
      );

      // Generate speech with Deepgram - use MP3 format for better compatibility
      final result = await _deepgram.speak.text(
        text,
        queryParams: {
          'model': 'aura-asteria-en',
          'encoding': 'mp3',
          // Remove sample_rate and container for MP3
        },
      );

      if (result.data != null && result.data!.isNotEmpty) {
        // Save audio data to temporary file for better compatibility
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(
          '${tempDir.path}/deepgram_tts_${DateTime.now().millisecondsSinceEpoch}.mp3',
        );

        await tempFile.writeAsBytes(result.data!);

        // Play the audio file using audioplayers
        await _audioPlayer.play(
          DeviceFileSource(tempFile.path),
          mode: PlayerMode.mediaPlayer,
        );

        // Clean up the temp file after a delay
        Future.delayed(const Duration(minutes: 1), () {
          try {
            if (tempFile.existsSync()) {
              tempFile.deleteSync();
            }
          } catch (e) {
            log('Error cleaning up temp file: $e');
          }
        });

        log('Deepgram TTS audio playback started successfully');
        return true;
      } else {
        log('Deepgram TTS returned empty audio data');
        _onComplete?.call();
        _onComplete = null;
        return false;
      }
    } catch (e, stackTrace) {
      log('Error in Deepgram speakText: $e');
      log('Stack trace: $stackTrace');
      _onComplete?.call();
      _onComplete = null;
      return false;
    }
  }

  // Stop current audio playback
  Future<void> stopSpeaking() async {
    if (_isDisposed) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.stop();
        _isPlaying = false;
        log('Deepgram TTS playback stopped');
      }
    } catch (e) {
      log('Error stopping Deepgram TTS: $e');
    }
  }

  // Pause current audio playback
  Future<void> pauseSpeaking() async {
    if (_isDisposed) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        log('Deepgram TTS playback paused');
      }
    } catch (e) {
      log('Error pausing Deepgram TTS: $e');
    }
  }

  // Resume paused audio playback
  Future<void> resumeSpeaking() async {
    if (_isDisposed) return;

    try {
      await _audioPlayer.resume();
      log('Deepgram TTS playback resumed');
    } catch (e) {
      log('Error resuming Deepgram TTS: $e');
    }
  }

  // Check if TTS is currently playing
  bool get isPlaying => !_isDisposed && _isPlaying;

  // Get current text being spoken
  String? get currentText => _currentText;

  // Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    if (_isDisposed) return;

    try {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
      log('Deepgram TTS volume set to: $volume');
    } catch (e) {
      log('Error setting Deepgram TTS volume: $e');
    }
  }

  // Test the TTS service with a simple phrase
  Future<bool> testTTS() async {
    try {
      log('Testing Deepgram TTS service...');
      return await speakText(
        'Hello, this is a test of the Deepgram text to speech service.',
      );
    } catch (e) {
      log('Deepgram TTS test failed: $e');
      return false;
    }
  }

  // Get available Deepgram TTS models
  List<String> getAvailableModels() {
    return [
      'aura-asteria-en',
      'aura-luna-en',
      'aura-stella-en',
      'aura-athena-en',
      'aura-hera-en',
      'aura-orion-en',
      'aura-arcas-en',
      'aura-perseus-en',
      'aura-angus-en',
      'aura-orpheus-en',
      'aura-helios-en',
      'aura-zeus-en',
    ];
  }

  // Dispose resources
  void dispose() {
    if (!_isDisposed) {
      log('Disposing Deepgram TTS service');
      _isDisposed = true;
      _audioPlayer.dispose();
      _onComplete = null;
      _currentText = null;
    }
  }
}
