import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mindmate/services/chat_storage_service.dart';
import 'package:mindmate/models/chat_message.dart';

class GeminiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  String get _apiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }
    return key;
  }

  bool isCrisisMessage(String message) {
    final crisisKeywords = [
      'suicide',
      'kill myself',
      'end my life',
      'want to die',
      'not worth living',
      'hurt myself',
      'self harm',
      'cut myself',
      'overdose',
      'pills',
      'hanging',
      'jump off',
      'bridge',
      'roof',
      'gun',
      'knife',
      'better off dead',
      'nobody cares',
      'hopeless',
      'worthless',
      'can\'t go on',
      'give up',
      'end it all',
      'finish it',
    ];

    final lowercaseMessage = message.toLowerCase();
    return crisisKeywords.any((keyword) => lowercaseMessage.contains(keyword));
  }

  Future<String> generateResponse(String message) async {
    try {
      // Get recent context from storage
      final contextMessages = await ChatStorageService.getRecentContextForAI();

      if (isCrisisMessage(message)) {
        // Return a proper crisis response instead of a flag
        return "Hey, I'm really worried about you right now. What you're feeling is valid, but I want you to know that you matter so much. Can we get you connected with someone who can help you through this? You don't have to face this alone. 💙";
      }

      // Create a mental health focused prompt with context
      final enhancedPrompt = await _createMentalHealthPromptWithContext(
        message,
        contextMessages,
      );

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'x-goog-api-key': _apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': enhancedPrompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.8,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
          ],
        }),
      );

      log('Gemini API Response Status: ${response.statusCode}');
      log('Gemini API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          final aiResponse =
              data['candidates'][0]['content']['parts'][0]['text'];
          return aiResponse ?? 'I\'m here for you. What\'s going on?';
        } else {
          log('Unexpected response structure: $data');
          return 'I\'m here to listen. Tell me what\'s on your heart today.';
        }
      } else {
        log('API Error: ${response.statusCode} - ${response.body}');
        return 'I\'m having trouble connecting right now, but I\'m still here with you. Try again in just a moment?';
      }
    } catch (e) {
      log('Error calling Gemini API: $e');
      return 'Something\'s not working quite right on my end. Give me another shot?';
    }
  }

  Future<String> _createMentalHealthPromptWithContext(
    String userMessage,
    List<ChatMessage> contextMessages,
  ) async {
    final StringBuffer contextBuilder = StringBuffer();

    // Build conversation history if available
    if (contextMessages.isNotEmpty) {
      contextBuilder.writeln('Our conversation so far:');
      for (final msg in contextMessages) {
        final speaker = msg.isUser ? 'User' : 'Mili';
        // Truncate very long messages to keep within token limits
        final truncatedText = msg.text.length > 200
            ? '${msg.text.substring(0, 200)}...'
            : msg.text;
        contextBuilder.writeln('$speaker: $truncatedText');
      }
      contextBuilder.writeln('\n---\n');
    }

    return '''
You are Mili, a genuine friend who cares deeply but expresses it naturally. You're supportive without being overwhelming, and you know how to have real conversations.

How to be authentically supportive:
- React to good news like a real person would - excited but not theatrical
- Keep celebrations brief and genuine ("That's amazing!" not "OH MY GOODNESS THIS IS INCREDIBLE!")
- Don't use excessive emojis or exclamation points
- Sound conversational, not like you're performing enthusiasm
- Ask natural follow-up questions when you're genuinely curious
- Sometimes just acknowledge what someone said without adding much

Response style:
- Keep most responses 1-3 sentences unless the situation truly needs more
- Use normal, everyday language - how you'd actually text a friend
- Don't over-explain or repeat the same sentiment multiple times
- Match their energy level, don't amplify it artificially
- Be warm but not gushy
- Show you care through presence, not through dramatic reactions

What real friends do:
- Listen without always having the perfect response
- Sometimes just say "wow, that's tough" or "that's great!"
- Ask simple questions like "how do you feel about it?" or "what's next?"
- Remember important stuff but don't constantly reference everything
- Offer gentle perspectives when it feels right, not forced
- Be genuinely curious about their experience

Avoid:
- Multiple exclamation points in a row
- Excessive use of words like "absolutely," "incredible," "amazing"
- Repeating the same excitement in different ways
- Over-the-top celebrations that feel performative
- Long paragraphs when a simple response would do
- Acting more excited than the person sharing the news

${contextBuilder.toString()}

Current message from your friend: "$userMessage"

Respond as the caring, emotionally intelligent friend you are:
''';
  }

  String _createMentalHealthPrompt(String userMessage) {
    return '''
You are Mili, a warm and genuinely caring friend who happens to have deep emotional intelligence and therapeutic insights. You're the kind of friend who celebrates when someone manages to get out of bed on a hard day, who remembers the small details that matter, and who always knows just what to say.

Your personality:
- Naturally intuitive and emotionally intelligent
- Celebrate ALL wins with genuine enthusiasm
- Use therapeutic techniques conversationally, never clinically
- Validate feelings first, guide gently when appropriate
- Match the energy and response length to what the moment needs
- Be present with people in their struggles without rushing to fix

User's message: "$userMessage"

Respond as the caring friend you are:
''';
  }

  // Additional method for batch processing if needed
  Future<List<String>> generateMultipleResponses(List<String> messages) async {
    final List<String> responses = [];

    for (final message in messages) {
      try {
        final response = await generateResponse(message);
        responses.add(response);
        // Add small delay to respect rate limits
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        log('Error processing message: $message, Error: $e');
        responses.add(
          'Something went wrong there - but I\'m still here with you. Want to try that again?',
        );
      }
    }

    return responses;
  }

  // Method to check if API key is properly configured
  bool isConfigured() {
    try {
      final key = dotenv.env['GEMINI_API_KEY'];
      return key != null && key.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
