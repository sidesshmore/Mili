import 'package:flutter/material.dart';
import 'package:mindmate/constants.dart';
import 'package:mindmate/features/Home/widgets/micInput.dart';
import 'package:mindmate/features/Home/widgets/textInput.dart';
import 'package:mindmate/services/gemini_service.dart';

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

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _textController.text.trim().isNotEmpty;
    });
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(
        ChatMessage(
          text: "Hi there! 👋 I'm your MindMate. How are you feeling today?",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: isUser, timestamp: DateTime.now()),
      );
    });
    _scrollToBottom();
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

  @override
  Widget build(BuildContext context) {
    // Initialize Globals for this context
    Globals.initialize(context);

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
                      return _buildMessageBubble(message);
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
                  // Send/Mic Button - Replace existing section with this
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

  void _showMicInputModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => Container(
        padding: EdgeInsets.all(Globals.screenWidth * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: Globals.screenWidth * 0.1,
              height: 4,
              margin: EdgeInsets.only(bottom: Globals.screenHeight * 0.02),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Text(
              'Voice Message',
              style: TextStyle(
                fontSize: Globals.screenWidth * 0.05,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: Globals.screenHeight * 0.02),

            // Mic Input Widget
            MicInput(
              onTranscription: (text) {
                Navigator.pop(context);
                if (text.isNotEmpty) {
                  _handleMicInput(text);
                }
              },
            ),

            SizedBox(height: Globals.screenHeight * 0.02),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
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
    );
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

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
