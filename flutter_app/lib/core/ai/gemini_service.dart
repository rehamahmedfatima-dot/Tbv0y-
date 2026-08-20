// داخل ملف flutter_app/lib/core/ai/gemini_service.dart

static const _modelName = 'gemini-1.5-flash';
static const _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

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
  };

  try {
    // إرسال الطلب إلى نقطة النهاية المعتمدة
    final url = '$_baseUrl/models/$_modelName:generateContent';

    final response = await _dio.post(
      url,
      data: body,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': EnvConfig.geminiApiKey, // تمرير المفتاح في الـ Header
        },
      ),
    );

    final candidates = response.data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) return '';
    final parts = candidates[0]['content']?['parts'] as List<dynamic>?;
    return (parts?[0]['text'] as String?)?.trim() ?? '';
  } on DioException catch (e) {
    print('Error Status: ${e.response?.statusCode}');
    rethrow;
  }
}
