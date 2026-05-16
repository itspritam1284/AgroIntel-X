import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiChatService {
  static const String _apiKey = 'AIzaSyCw6w-EJrtPuBrRWWMslTw39jmW9oRVY_Y';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent';

  final List<Map<String, dynamic>> _conversationHistory = [];
  
  Future<String> sendMessage(String userMessage) async {
    try {
      // Add user message to history
      _conversationHistory.add({
        'role': 'user',
        'parts': [
          {'text': userMessage},
        ],
      });

      // Build the request with conversation history
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': _conversationHistory,
          'systemInstruction': {
            'parts': [
              {
                'text':
                    '''You are an expert agricultural AI assistant specializing in farming advice. 
Your role is to help farmers with:
- Crop selection and planning
- Irrigation and water management
- Pest and disease control
- Soil health and fertilization
- Weather-based recommendations
- Sustainable farming practices
- Modern farming technologies

Provide practical, actionable advice. Be friendly, supportive, and use simple language.
When relevant, consider Indian farming contexts and local crops.
Keep responses concise but informative (2-4 paragraphs max unless asked for detailed information).
Use emojis occasionally to make responses more engaging.''',
              },
            ],
          },
          'generationConfig': {
            'temperature': 0.8,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 2048,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse =
            data['candidates'][0]['content']['parts'][0]['text'] as String;

        // Add AI response to history
        _conversationHistory.add({
          'role': 'model',
          'parts': [
            {'text': aiResponse},
          ],
        });

        return aiResponse;
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get response: $e');
    }
  }

  void clearHistory() {
    _conversationHistory.clear();
  }

  int getMessageCount() {
    return _conversationHistory.length;
  }
}
