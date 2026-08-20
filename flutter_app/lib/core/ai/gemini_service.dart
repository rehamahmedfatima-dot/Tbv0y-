import 'package:dio/dio.dart';
import 'package:google_generative_ai/google_generative_ai.dart' show Content, TextPart;
import '../config/env_config.dart';

/// Talks to the Gemini API directly over HTTP (via Dio) instead of the
/// `google_generative_ai` package. That package has been officially
/// deprecated by Google — its GitHub repo is now archived as
/// "deprecated-generative-ai-dart" — and its generateContent() calls
/// return 404 even for currently-available models. Calling the REST
/// endpoint directly avoids that broken layer entirely. `Content` is
/// still imported from the old package purely as a plain data holder
/// (role + text) for compatibility with existing call sites like the AI
/// Coach chat screen — no network code from that package is used.
class GeminiService {
  static const _modelName = 'gemini-2.5-flash';
  static const _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  GeminiService._internal() : _dio = Dio();
  static final GeminiService instance = GeminiService._internal();
  final Dio _dio;

  Future<String> _post({
    required List<Map<String, dynamic>> contents,
    String? systemInstruction,
    double temperature = 0.8,
    int maxOutputTokens = 1024,
    String? responseMimeType,
  }) async {
    final body = {
      'contents': contents,
      'generationConfig': {
        'temperature': temperature,
        'maxOutputTokens': maxOutputTokens,
        if (responseMimeType != null) 'responseMimeType': responseMimeType,
      },
      if (systemInstruction != null)
        'systemInstruction': {
          'parts': [
            {'text': systemInstruction}
          ]
        },
      'safetySettings': [
        {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
      ],
    };

    final response = await _dio.post(
      '$_baseUrl/models/$_modelName:generateContent',
      queryParameters: {'key': EnvConfig.geminiApiKey},
      data: body,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    final candidates = response.data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) return '';
    final parts = candidates[0]['content']?['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) return '';
    return (parts[0]['text'] as String?)?.trim() ?? '';
  }

  /// One-off prompt → plain text response.
  Future<String> generateText(String prompt, {String? systemInstruction}) {
    return _post(
      contents: [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      systemInstruction: systemInstruction,
    );
  }

  /// Prompt → parsed JSON string. Used for AI missions, goal roadmaps,
  /// identity → habit conversion, and story reports.
  Future<String> generateJson(String prompt) {
    return _post(
      contents: [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      temperature: 0.4,
      maxOutputTokens: 2048,
      responseMimeType: 'application/json',
    );
  }

  /// Multi-turn chat session for the AI Coach conversation screen.
  ChatSession startChat({List<Content>? history, String? systemInstruction}) {
    return ChatSession._(
      service: this,
      systemInstruction: systemInstruction,
      history: history ?? [],
    );
  }
}

/// Drop-in replacement for google_generative_ai's ChatSession — keeps its
/// own turn history and calls GeminiService for each new message.
class ChatSession {
  ChatSession._({required this.service, this.systemInstruction, required this.history});

  final GeminiService service;
  final String? systemInstruction;
  final List<Content> history;

  Future<GenerateContentResponse> sendMessage(Content message) async {
    history.add(message);

    final contents = history
        .map((c) => {
              'role': c.role == 'model' ? 'model' : 'user',
              'parts': c.parts
                  .whereType<TextPart>()
                  .map((p) => {'text': p.text})
                  .toList(),
            })
        .toList();

    final text = await service._post(
      contents: contents,
      systemInstruction: systemInstruction,
    );

    history.add(Content.model([TextPart(text)]));
    return GenerateContentResponse(text);
  }
}

/// Minimal stand-in for the SDK's response type — exposes just `.text`,
/// which is all existing call sites use.
class GenerateContentResponse {
  const GenerateContentResponse(this.text);
  final String? text;
}
