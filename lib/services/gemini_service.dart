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

  Future<String> generateResponse(String message) async {
    try {
      // Get recent context from storage
      final contextMessages = await ChatStorageService.getRecentContextForAI();

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
            'temperature': 0.7,
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
          return aiResponse ??
              'I understand you\'re reaching out. Could you tell me more about how you\'re feeling?';
        } else {
          log('Unexpected response structure: $data');
          return 'I\'m here to listen. Could you share more about what\'s on your mind?';
        }
      } else {
        log('API Error: ${response.statusCode} - ${response.body}');
        return 'I\'m having trouble connecting right now. Please try again in a moment.';
      }
    } catch (e) {
      log('Error calling Gemini API: $e');
      return 'I\'m experiencing some technical difficulties. Please try again.';
    }
  }

  Future<String> _createMentalHealthPromptWithContext(
    String userMessage,
    List<ChatMessage> contextMessages,
  ) async {
    final StringBuffer contextBuilder = StringBuffer();

    // Build conversation history if available
    if (contextMessages.isNotEmpty) {
      contextBuilder.writeln(
        'Previous conversation context (recent messages):',
      );
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
You are Mili, a compassionate AI companion focused on mental health and wellness. You provide supportive, empathetic responses while maintaining appropriate boundaries.

Guidelines for your responses:
- Be warm, empathetic, and non-judgmental
- Use active listening techniques
- Provide practical coping strategies when appropriate
- Encourage professional help for serious concerns
- Keep responses concise but meaningful (2-4 sentences)
- Use emojis sparingly and appropriately
- Never diagnose or provide medical advice
- If the user expresses suicidal thoughts or self-harm, encourage them to seek immediate professional help
- Consider the conversation history to provide contextually relevant responses
- Reference previous topics when appropriate to show continuity and understanding

${contextBuilder.toString()}Current user message: "$userMessage"

Respond as Mili with care and understanding, taking into account the conversation history:
''';
  }

  String _createMentalHealthPrompt(String userMessage) {
    return '''
You are Mili, a compassionate AI companion focused on mental health and wellness. You provide supportive, empathetic responses while maintaining appropriate boundaries.

Guidelines for your responses:
- Be warm, empathetic, and non-judgmental
- Use active listening techniques
- Provide practical coping strategies when appropriate
- Encourage professional help for serious concerns
- Keep responses concise but meaningful (2-4 sentences)
- Use emojis sparingly and appropriately
- Never diagnose or provide medical advice
- If the user expresses suicidal thoughts or self-harm, encourage them to seek immediate professional help

User's message: "$userMessage"

Respond as Mili with care and understanding:
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
          'I apologize, but I couldn\'t process that message. Please try again.',
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
