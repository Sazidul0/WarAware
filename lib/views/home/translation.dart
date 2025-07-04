// lib/screens/translation_screen.dart

import 'package:flutter/material.dart';
import '../../services/gemeni_services.dart'; // Adjust import path

class TranslationScreen extends StatefulWidget {
  final String description;
  final String username;

  const TranslationScreen({
    super.key,
    required this.description,
    required this.username,
  });

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  // List of languages for the dropdown
  final List<String> _languages = [
    'Arabic',
    'Hebrew',
    'Bangla',
    'English',
    'French',
    'Spanish',
    'German'
  ];
  late String _selectedLanguage;

  // State variables
  String _translatedText = '';
  bool _isLoading = false;
  final GeminiService _geminiService = GeminiService();

  @override
  void initState() {
    super.initState();
    // Set the default language
    _selectedLanguage = _languages.first;
  }

  Future<void> _performTranslation() async {
    if (widget.description.isEmpty) return;

    setState(() {
      _isLoading = true;
      _translatedText = ''; // Clear previous translation
    });

    final result = await _geminiService.translateText(
      textToTranslate: widget.description,
      targetLanguage: _selectedLanguage,
    );

    setState(() {
      _translatedText = result;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Translate Post'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Original Text Section ---
            Text(
              'Original text by ${widget.username}',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12.0),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                widget.description,
                style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 24),

            // --- Language Selection ---
            const Text(
              'Translate to:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: DropdownButton<String>(
                value: _selectedLanguage,
                isExpanded: true,
                underline: const SizedBox(), // Hides the default underline
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedLanguage = newValue;
                      // Optional: Clear translation when language changes
                      _translatedText = '';
                    });
                  }
                },
                items: _languages.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // --- Translate Button ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.translate),
                label: const Text('Translate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: _isLoading ? null : _performTranslation,
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // --- Translation Result Section ---
            const Text(
              'Translation:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12.0),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Text(
                _translatedText.isEmpty
                    ? 'Translation will appear here...'
                    : _translatedText,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}