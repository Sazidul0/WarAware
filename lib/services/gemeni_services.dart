import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // Use a static instance to prevent re-initialization
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;

  late final GenerativeModel _model;

  GeminiService._internal() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    // This check is crucial to ensure your .env setup is working.
    if (apiKey == null) {
      print('FATAL ERROR: GEMINI_API_KEY not found. Ensure .env file is set up correctly.');
      throw Exception('API Key not found');
    }

    _model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: apiKey,
    );
  }

  Future<String> translateText({
    required String textToTranslate,
    required String targetLanguage,
  }) async {
    try {
      final prompt =
          'Translate the following text into $targetLanguage. Provide only the raw translated text, without any additional explanations, introductions, or formatting. The text to translate is: "$textToTranslate"';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!;
      } else {
        return 'Translation failed. The model returned no text.';
      }
    } catch (e) {
      print('An error occurred during translation: $e');
      return 'Error: Could not translate text.';
    }
  }
}