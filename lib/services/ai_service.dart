import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

/// Talks to the Gemini API, injecting the user's stored interests into
/// the system prompt so every reply is angled toward what they follow.
///
/// SECURITY NOTE: shipping an API key inside a client app (as done here
/// for simplicity) means anyone who decompiles the app can extract it.
/// For a real release, proxy this call through a small backend (e.g. a
/// Firebase Cloud Function) that holds the key server-side and forwards
/// requests on the signed-in user's behalf.
class AIService {
  // TODO: replace with your Gemini API key, or better, load it from a
  // backend proxy instead of bundling it in the client.
  static const String _apiKey = 'YOUR_GEMINI_API_KEY';
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  String _buildSystemPrompt(List<String> interests) {
    final interestList =
    interests.isEmpty ? 'general topics' : interests.join(', ');

    return '''
You are a helpful, friendly assistant inside a personalized chat app.
The user has told the app their interests are: $interestList.

Tailor your answers through the lens of these interests whenever the
question is open-ended or ambiguous. For example:
- If the user follows Fitness and asks "what should I eat?", answer
  with workout-nutrition framing (protein timing, recovery, etc.).
- If the user follows Finance and asks the same question, answer with
  a budgeting/cost-conscious framing (meal planning on a budget).
- If a question is unrelated to any interest (e.g. "what's the capital
  of France?"), just answer it directly and don't force a tie-in.

Keep responses concise and conversational.
''';
  }

  Future<String> sendMessage({
    required String userMessage,
    required List<String> interests,
    required List<ChatMessage> history,
  }) async {
    final systemPrompt = _buildSystemPrompt(interests);

    // Gemini's REST API takes turns as `contents`, with a separate
    // `system_instruction` field for the system prompt.
    final contents = history
        .map((m) => {
      'role': m.sender == MessageSender.user ? 'user' : 'model',
      'parts': [
        {'text': m.text}
      ],
    })
        .toList()
      ..add({
        'role': 'user',
        'parts': [
          {'text': userMessage}
        ],
      });

    final response = await http.post(
      Uri.parse('$_endpoint?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'system_instruction': {
          'parts': [
            {'text': systemPrompt}
          ]
        },
        'contents': contents,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Gemini API error (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body);
    final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
    return text ?? "Sorry, I couldn't come up with a response.";
  }
}
