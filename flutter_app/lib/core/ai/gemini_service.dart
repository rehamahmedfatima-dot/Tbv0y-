import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/env_config.dart';

/// Thin wrapper around the Gemini SDK. Every AI feature in TBVOY
/// (AI Coach, journal summaries, daily missions, future-self letters,
/// annual "Story of Your Best Version" reports) goes through this service
/// so model choice, safety settings, and error handling live in one place.
class GeminiService {
  GeminiService._internal()
      : _chatModel = GenerativeModel(
          model: 'gemini-2.0-flash',
          apiKey: EnvConfig.geminiApiKey,
          generationConfig: GenerationConfig(
            temperature: 0.8,
            maxOutputTokens: 1024,
          ),
          safetySettings: [
            SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
            SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
            SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
            SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
          ],
        ),
        _jsonModel = GenerativeModel(
          model: 'gemini-2.0-flash',
          apiKey: EnvConfig.geminiApiKey,
          generationConfig: GenerationConfig(
            temperature: 0.4,
            maxOutputTokens: 2048,
            responseMimeType: 'application/json',
          ),
        );

  static final GeminiService instance = GeminiService._internal();

  final GenerativeModel _chatModel;   // free-form coaching / motivational text
  final GenerativeModel _jsonModel;   // structured output (missions, roadmaps, reports)

  /// One-off prompt → plain text response. Used for motivational messages,
  /// journal summaries, mood-pattern insights, future-self letters.
  Future<String> generateText(String prompt, {String? systemInstruction}) async {
    final model = systemInstruction == null
        ? _chatModel
        : GenerativeModel(
            model: 'gemini-2.0-flash',
            apiKey: EnvConfig.geminiApiKey,
            systemInstruction: Content.system(systemInstruction),
          );
    final response = await model.generateContent([Content.text(prompt)]);
    return response.text?.trim() ?? '';
  }

  /// Prompt → parsed JSON. Used for AI missions, goal roadmaps, identity →
  /// habit conversion, and the structured "Story of Your Best Version" report.
  Future<String> generateJson(String prompt) async {
    final response = await _jsonModel.generateContent([Content.text(prompt)]);
    return response.text?.trim() ?? '{}';
  }

  /// Multi-turn chat session for the AI Coach conversation screen —
  /// keeps context across a single conversation without resending history
  /// manually each call.
  ChatSession startChat({List<Content>? history, String? systemInstruction}) {
    final model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: EnvConfig.geminiApiKey,
      systemInstruction: systemInstruction != null ? Content.system(systemInstruction) : null,
      generationConfig: GenerationConfig(temperature: 0.8, maxOutputTokens: 1024),
    );
    return model.startChat(history: history);
  }
}
