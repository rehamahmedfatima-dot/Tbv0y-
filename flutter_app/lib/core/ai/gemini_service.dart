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

    try {
      // تعديل الرابط ليتوافق مع v1beta وبادئة النموذج
      final url = '$_baseUrl/models/gemini-1.5-flash:generateContent';

      final response = await _dio.post(
        url,
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': EnvConfig.geminiApiKey,
          },
        ),
      );

      final candidates = response.data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) return '';
      final parts = candidates[0]['content']?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) return '';
      return (parts[0]['text'] as String?)?.trim() ?? '';
    } on DioException catch (e) {
      print('Gemini API Error Status: ${e.response?.statusCode}');
      print('Gemini API Response: ${e.response?.data}');
      rethrow;
    }
}
