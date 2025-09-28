import 'package:flutter/material.dart';
import 'package:mindmate/constants.dart';
import 'package:mindmate/features/Home/widgets/micInput.dart';
import 'package:mindmate/features/Home/widgets/textInput.dart';
import 'package:mindmate/features/Home/widgets/waveAnimation.dart';
import 'package:mindmate/models/chat_message.dart';
import 'package:mindmate/services/chat_storage_service.dart';
import 'package:mindmate/services/chat_summary_service.dart';
import 'package:mindmate/services/gemini_service.dart';
import 'package:mindmate/services/deepgram_tts_service.dart';
import 'dart:developer';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();
  final FocusNode _textFocusNode = FocusNode();

  bool _isLoading = false;
  bool _hasText = false;
  bool _isInitialized = false;
  bool _isRecording = false;

  final Map<int, bool> _isMessagePlaying = {};
  final DeepgramTTSService _ttsService = DeepgramTTSService();

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _textController.addListener(_onTextChanged);
  }

  // Initialize chat storage and load previous messages
  Future<void> _initializeChat() async {
    try {
      // Initialize Hive storage
      await ChatStorageService.init();

      // Load previous messages for the current user
      final savedMessages =
          await ChatStorageService.getMessagesForCurrentUser();

      setState(() {
        _messages.clear();
        _messages.addAll(savedMessages);
        _isInitialized = true;
      });

      await ChatSummaryService.checkAndGenerateSummaries();

      // Add welcome message only if no previous messages exist
      if (_messages.isEmpty) {
        _addWelcomeMessage();
      }

      // Scroll to bottom after loading messages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      // Log storage info
      final storageInfo = await ChatStorageService.getStorageInfo();
      log('Chat initialized - Storage info: $storageInfo');
    } catch (e) {
      log('Error initializing chat: $e');
      setState(() {
        _isInitialized = true;
      });
      // Still add welcome message if initialization fails
      _addWelcomeMessage();
    }
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _textController.text.trim().isNotEmpty;
    });
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      text: "Hi there! 👋 I'm your MindMate. How are you feeling today?",
      isUser: false,
      timestamp: DateTime.now(),
      userId: '', // Will be set when saving
    );

    setState(() {
      _messages.add(welcomeMessage);
    });

    // Save welcome message to storage
    _saveMessageToStorage(welcomeMessage);
  }

  void _addMessage(String text, bool isUser) {
    final message = ChatMessage(
      text: text,
      isUser: isUser,
      timestamp: DateTime.now(),
      userId: '', // Will be set when saving
    );

    setState(() {
      _messages.add(message);
    });

    // Save message to storage
    _saveMessageToStorage(message);

    _scrollToBottom();
  }

  // Save message to Hive storage
  Future<void> _saveMessageToStorage(ChatMessage message) async {
    try {
      await ChatStorageService.saveMessage(message);
    } catch (e) {
      log('Error saving message to storage: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Add user message
    _addMessage(message, true);

    // Clear text field
    _textController.clear();
    setState(() {
      _hasText = false;
    });

    setState(() {
      _isLoading = true;
    });

    try {
      // Get AI response from Gemini (now includes context automatically)
      final response = await _geminiService.generateResponse(message);
      _addMessage(response, false);

      await ChatSummaryService.checkAndGenerateSummaries();

      // Log context info for debugging
      final contextMessages = await ChatStorageService.getRecentContextForAI();
      log('Sent context of ${contextMessages.length} messages to Gemini');
    } catch (e) {
      log('Error generating AI response: $e');
      _addMessage(
        "Sorry, I'm having trouble right now. Please try again.",
        false,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleTTS(String text, int messageIndex) async {
    try {
      // If this message is currently playing, stop it
      if (_isMessagePlaying[messageIndex] == true) {
        await _ttsService.stopSpeaking();
        setState(() {
          _isMessagePlaying[messageIndex] = false;
        });
        return;
      }

      // Stop any other playing messages first
      await _ttsService.stopSpeaking();
      setState(() {
        _isMessagePlaying.clear();
        _isMessagePlaying[messageIndex] = true;
      });

      log(
        'Attempting to play TTS for message: ${text.substring(0, text.length > 100 ? 100 : text.length)}...',
      );

      // Start playing the current message with completion callback
      final success = await _ttsService.speakText(
        text,
        onComplete: () {
          if (mounted) {
            setState(() {
              _isMessagePlaying[messageIndex] = false;
            });
          }
        },
      );

      if (!success) {
        setState(() {
          _isMessagePlaying[messageIndex] = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to play audio. Please check your device\'s TTS settings.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    } catch (e, stackTrace) {
      log('Error in TTS toggle: $e');
      log('Stack trace: $stackTrace');

      setState(() {
        _isMessagePlaying[messageIndex] = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing audio: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _showSummaryStats() async {
    final stats = await ChatSummaryService.getSummaryStats();
    log('Summary Stats: $stats');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Summaries: ${stats['totalSummaries']}, '
            'Messages: ${stats['currentMessageCount']}, '
            'Next at: ${stats['nextSummaryAt']}',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleTextSubmit(String text) {
    _sendMessage(text);
  }

  void _handleMicInput(String transcribedText) {
    // Reset recording state when transcription is received
    setState(() {
      _isRecording = false;
    });
    _sendMessage(transcribedText);
  }

  void _onRecordingStateChanged(bool isRecording) {
    setState(() {
      _isRecording = isRecording;
    });
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  // Clear chat history
  Future<void> _clearChatHistory() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Chat History'),
          content: const Text(
            'Are you sure you want to clear all your chat history? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ChatStorageService.clearMessagesForCurrentUser();
                  setState(() {
                    _messages.clear();
                  });
                  _addWelcomeMessage();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chat history cleared successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error clearing chat history: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Clear', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Initialize Globals for this context
    Globals.initialize(context);

    // Show loading indicator if not initialized
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('MindMate')),
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Chat Messages - Fixed gesture detector behavior
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: Globals.screenWidth * 0.04,
                ),
                child: GestureDetector(
                  onTap: _dismissKeyboard,
                  behavior: HitTestBehavior.opaque,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isLoading) {
                        return _buildTypingIndicator();
                      }

                      final message = _messages[index];
                      return _buildMessageBubble(message, index);
                    },
                  ),
                ),
              ),
            ),

            // Modern Input Section - No gesture detector here to avoid conflicts
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Globals.screenWidth * 0.04,
                vertical: Globals.screenHeight * 0.015,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Text Input Field
                  Expanded(
                    child: _isRecording
                        ? const WaveAnimation() // Show wave animation when recording
                        : Container(
                            constraints: BoxConstraints(
                              maxHeight: Globals.screenHeight * 0.15,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                              color: Colors.grey[50],
                            ),
                            child: TextField(
                              controller: _textController,
                              focusNode: _textFocusNode,
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                hintStyle: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: Globals.screenWidth * 0.04,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: Globals.screenWidth * 0.05,
                                  vertical: Globals.screenHeight * 0.015,
                                ),
                              ),
                              style: TextStyle(
                                fontSize: Globals.screenWidth * 0.04,
                              ),
                              maxLines: null,
                              textCapitalization: TextCapitalization.sentences,
                              onSubmitted: _hasText ? _handleTextSubmit : null,
                              onTap: () {
                                _textFocusNode.requestFocus();
                              },
                            ),
                          ),
                  ),

                  SizedBox(width: Globals.screenWidth * 0.02),

                  // Send/Mic Button
                  GestureDetector(
                    onTap: () {
                      if (_hasText) {
                        _sendMessage(_textController.text);
                      }
                      // Remove the else clause as MicInput handles its own tap
                    },
                    child: _hasText
                        ? Container(
                            width: Globals.screenWidth * 0.12,
                            height: Globals.screenWidth * 0.12,
                            decoration: BoxDecoration(
                              color: Globals.customBlue,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Globals.customBlue.withOpacity(0.3),
                                  spreadRadius: 1,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: Globals.screenWidth * 0.06,
                            ),
                          )
                        : MicInput(
                            onTranscription: _handleMicInput,
                            onRecordingStateChanged: _onRecordingStateChanged,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, int index) {
    return Container(
      margin: EdgeInsets.only(
        bottom: Globals.screenHeight * 0.01,
        left: message.isUser ? Globals.screenWidth * 0.15 : 0,
        right: message.isUser ? 0 : Globals.screenWidth * 0.15,
      ),
      child: Align(
        alignment: message.isUser
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: () => _showMessageOptions(message, index),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: Globals.screenWidth * 0.04,
              vertical: Globals.screenHeight * 0.015,
            ),
            decoration: BoxDecoration(
              color: message.isUser ? Globals.customBlue : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        message.text,
                        style: TextStyle(
                          color: message.isUser ? Colors.white : Colors.black87,
                          fontSize: Globals.screenWidth * 0.04,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    // Add TTS button only for AI messages
                    if (!message.isUser) ...[
                      SizedBox(width: Globals.screenWidth * 0.02),
                      GestureDetector(
                        onTap: () => _toggleTTS(message.text, index),
                        child: Container(
                          padding: EdgeInsets.all(Globals.screenWidth * 0.015),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            (_isMessagePlaying[index] ?? false)
                                ? Icons.stop_rounded
                                : Icons.volume_up_rounded,
                            size: Globals.screenWidth * 0.04,
                            color: Globals.customBlue,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: Globals.screenHeight * 0.005),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    color: message.isUser
                        ? Colors.white.withOpacity(0.7)
                        : Colors.grey[500],
                    fontSize: Globals.screenWidth * 0.03,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMessageOptions(ChatMessage message, int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(Globals.screenWidth * 0.04),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Message'),
              onTap: () {
                Navigator.pop(context);
                // Implement copy to clipboard functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message copied to clipboard')),
                );
              },
            ),
            if (message.isUser)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete Message',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _deleteMessage(index);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMessage(int index) async {
    try {
      await ChatStorageService.deleteMessage(index);
      setState(() {
        _messages.removeAt(index);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: EdgeInsets.only(
        bottom: Globals.screenHeight * 0.01,
        right: Globals.screenWidth * 0.15,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: Globals.screenWidth * 0.04,
            vertical: Globals.screenHeight * 0.015,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: Globals.screenWidth * 0.05,
                height: Globals.screenWidth * 0.05,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Globals.customBlue),
                ),
              ),
              SizedBox(width: Globals.screenWidth * 0.02),
              Text(
                'MindMate is typing...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: Globals.screenWidth * 0.035,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _textFocusNode.dispose();
    _ttsService.dispose();
    super.dispose();
  }
}
