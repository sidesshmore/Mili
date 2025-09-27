import 'package:flutter/material.dart';
import 'package:mindmate/constants.dart';
import 'package:mindmate/features/Home/widgets/micInput.dart';
import 'package:mindmate/features/Home/widgets/textInput.dart';
import 'package:mindmate/models/chat_message.dart';
import 'package:mindmate/services/chat_storage_service.dart';
import 'package:mindmate/services/gemini_service.dart';
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
      // Get AI response from Gemini
      final response = await _geminiService.generateResponse(message);
      _addMessage(response, false);
    } catch (e) {
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

  void _handleTextSubmit(String text) {
    _sendMessage(text);
  }

  void _handleMicInput(String transcribedText) {
    _sendMessage(transcribedText);
  }

  void _dismissKeyboard() {
    // Only dismiss if the text field is not actively focused
    if (!_textFocusNode.hasFocus) {
      FocusScope.of(context).unfocus();
    }
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

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chat history cleared successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error clearing chat history: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
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
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(Globals.screenWidth * 0.04),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MindMate Chat',
                              style: TextStyle(
                                fontSize: Globals.screenWidth * 0.06,
                                fontWeight: FontWeight.w700,
                                color: Globals.customBlue,
                              ),
                            ),
                            SizedBox(height: Globals.screenHeight * 0.005),
                            Text(
                              'Your AI companion for mental wellness',
                              style: TextStyle(
                                fontSize: Globals.screenWidth * 0.035,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Clear chat button
                      IconButton(
                        onPressed: _clearChatHistory,
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.grey[600],
                          size: Globals.screenWidth * 0.06,
                        ),
                        tooltip: 'Clear Chat History',
                      ),
                    ],
                  ),
                  // Message count indicator
                  if (_messages.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(top: Globals.screenHeight * 0.01),
                      child: Text(
                        '${_messages.length} messages',
                        style: TextStyle(
                          fontSize: Globals.screenWidth * 0.03,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Chat Messages - Fixed gesture detector behavior
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: Globals.screenWidth * 0.04,
                ),
                child: GestureDetector(
                  onTap: () {
                    // Only dismiss keyboard if text field doesn't have focus
                    // and we're not tapping on a message bubble
                    if (!_textFocusNode.hasFocus) {
                      _dismissKeyboard();
                    }
                  },
                  behavior: HitTestBehavior.translucent,
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
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: Globals.screenHeight * 0.15,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
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
                        style: TextStyle(fontSize: Globals.screenWidth * 0.04),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: _hasText ? _handleTextSubmit : null,
                        onTap: () {
                          // Ensure the text field gets focus when tapped
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
                        : MicInput(onTranscription: _handleMicInput),
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
                Text(
                  message.text,
                  style: TextStyle(
                    color: message.isUser ? Colors.white : Colors.black87,
                    fontSize: Globals.screenWidth * 0.04,
                    fontWeight: FontWeight.w400,
                  ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting message: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
    super.dispose();
  }
}
