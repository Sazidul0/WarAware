// lib/services/gemini_service.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // Use a static instance to prevent re-initialization
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;

  late final GenerativeModel _model;

  GeminiService._internal() {
    // 1. THIS IS THE SECURE WAY: Fetch the key from the environment variables.
    // This avoids hardcoding your secret key in the source code.
    final apiKey = "AIzaSyASdyg9ljwo6Y3x72cupSwhuJuAO2TSu14";

    // This check is crucial to ensure your .env setup is working.
    if (apiKey == null) {
      print('FATAL ERROR: GEMINI_API_KEY not found. Ensure .env file is set up correctly.');
      throw Exception('API Key not found');
    }

    // 2. THIS IS THE MAIN FIX: We've changed the model name.
    // We use 'gemini-1.5-flash-latest' which is the current, fast, and recommended model.
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
      // The prompt is well-structured and should remain the same.
      final prompt =
          'Translate the following text into $targetLanguage. Provide only the raw translated text, without any additional explanations, introductions, or formatting. The text to translate is: "$textToTranslate"';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!;
      } else {
        // This can happen if the model returns an empty response due to safety settings.
        return 'Translation failed. The model returned no text.';
      }
    } catch (e) {
      // This will catch any network errors or API-specific errors from Google.
      // Check your Debug Console for the output of this print statement.
      print('An error occurred during translation: $e');
      return 'Error: Could not translate text.';
    }
  }
}