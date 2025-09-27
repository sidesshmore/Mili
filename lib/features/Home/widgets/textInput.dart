import 'package:flutter/material.dart';
import 'package:mindmate/constants.dart';

class TextInput extends StatefulWidget {
  final Function(String)? onMessageSent;
  final String? hintText;
  final bool showDialog;

  const TextInput({
    super.key,
    this.onMessageSent,
    this.hintText,
    this.showDialog = true,
  });

  @override
  State<TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<TextInput> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _colorAnimation;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _colorAnimation =
        ColorTween(
          begin: Globals.customBlue,
          end: Globals.customLightBlue,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    _animationController.repeat(reverse: true);
  }

  void _handleTap() {
    if (widget.showDialog) {
      _showTextInputDialog();
    } else if (widget.onMessageSent != null) {
      // If not showing dialog, this widget acts as a simple tap handler
      widget.onMessageSent!('');
    }
  }

  void _showTextInputDialog() {
    final textController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          child: Container(
            padding: EdgeInsets.all(Globals.screenWidth * 0.05),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.grey.shade50],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(Globals.screenWidth * 0.02),
                      decoration: BoxDecoration(
                        color: Globals.customBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        color: Globals.customBlue,
                        size: Globals.screenWidth * 0.06,
                      ),
                    ),
                    SizedBox(width: Globals.screenWidth * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Share Your Thoughts',
                            style: TextStyle(
                              fontSize: Globals.screenWidth * 0.05,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Express how you\'re feeling today',
                            style: TextStyle(
                              fontSize: Globals.screenWidth * 0.035,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.grey[500],
                        size: Globals.screenWidth * 0.06,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: Globals.screenHeight * 0.02),

                // Text Input Field
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: TextField(
                    controller: textController,
                    maxLines: 6,
                    autofocus: true,
                    style: TextStyle(
                      fontSize: Globals.screenWidth * 0.04,
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          widget.hintText ??
                          'How are you feeling today? Share your thoughts, concerns, or what\'s on your mind...',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: Globals.screenWidth * 0.035,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(
                        Globals.screenWidth * 0.04,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: Globals.screenHeight * 0.025),

                // Quick Response Chips
                Text(
                  'Quick responses:',
                  style: TextStyle(
                    fontSize: Globals.screenWidth * 0.035,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: Globals.screenHeight * 0.01),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildQuickResponseChip(
                      'I\'m feeling great today! 😊',
                      textController,
                    ),
                    _buildQuickResponseChip(
                      'I\'m a bit stressed 😰',
                      textController,
                    ),
                    _buildQuickResponseChip(
                      'I need someone to talk to 💭',
                      textController,
                    ),
                    _buildQuickResponseChip(
                      'I\'m feeling anxious 😟',
                      textController,
                    ),
                    _buildQuickResponseChip(
                      'I\'m having a rough day 😔',
                      textController,
                    ),
                  ],
                ),

                SizedBox(height: Globals.screenHeight * 0.025),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade400),
                          padding: EdgeInsets.symmetric(
                            vertical: Globals.screenHeight * 0.015,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: Globals.screenWidth * 0.04,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: Globals.screenWidth * 0.03),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          final message = textController.text.trim();
                          if (message.isNotEmpty) {
                            Navigator.pop(context);
                            widget.onMessageSent?.call(message);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Globals.customBlue,
                          padding: EdgeInsets.symmetric(
                            vertical: Globals.screenHeight * 0.015,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: Globals.screenWidth * 0.045,
                            ),
                            SizedBox(width: Globals.screenWidth * 0.02),
                            Text(
                              'Send Message',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: Globals.screenWidth * 0.04,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickResponseChip(
    String text,
    TextEditingController controller,
  ) {
    return GestureDetector(
      onTap: () {
        controller.text = text;
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Globals.screenWidth * 0.03,
          vertical: Globals.screenHeight * 0.008,
        ),
        decoration: BoxDecoration(
          color: Globals.customBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Globals.customBlue.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Globals.customBlue,
            fontSize: Globals.screenWidth * 0.03,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _isHovered ? 0.98 : _pulseAnimation.value,
            child: Container(
              height: Globals.screenHeight * 0.12,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _colorAnimation.value ?? Globals.customBlue,
                    Globals.customLightBlue,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Globals.customBlue.withOpacity(0.3),
                    spreadRadius: _isHovered ? 2 : 1,
                    blurRadius: _isHovered ? 8 : 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(Globals.screenWidth * 0.03),
                child: Row(
                  children: [
                    // Writing Icon with Animation
                    Container(
                      width: Globals.screenWidth * 0.15,
                      height: Globals.screenWidth * 0.15,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: Globals.screenWidth * 0.08,
                      ),
                    ),

                    SizedBox(width: Globals.screenWidth * 0.03),

                    // Text Content
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Write Down!',
                            style: TextStyle(
                              fontSize: Globals.screenWidth * 0.055,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: Globals.screenHeight * 0.005),
                          Text(
                            'Tap to share your thoughts',
                            style: TextStyle(
                              fontSize: Globals.screenWidth * 0.03,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Arrow Icon
                    Container(
                      padding: EdgeInsets.all(Globals.screenWidth * 0.02),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: Globals.screenWidth * 0.04,
                      ),
                    ),
                  ],
                ),
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
    super.dispose();
  }
}
