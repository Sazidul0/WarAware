import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/first_aid_guideline_model.dart';
import 'dart:convert';

class FirstAidViewModel extends ChangeNotifier {
  List<FirstAidGuideline> _guidelines = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<FirstAidGuideline> get guidelines => _guidelines;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  FirstAidViewModel() {
    // Fetch the guidelines when the ViewModel is created.
    fetchGuidelines();
  }

  // This method now fetches data from the JSON file.
  Future<void> fetchGuidelines() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Load the JSON file from assets as a string.
      final String response = await rootBundle.loadString('assets/guidelines.json');

      // 2. Decode the JSON string into a Dart List.
      final data = await json.decode(response) as List;

      // 3. Map the List of dynamic objects to a List of FirstAidGuideline models.
      _guidelines = data.map((item) => FirstAidGuideline.fromMap(item)).toList();

    } catch (e) {
      _errorMessage = 'Failed to load guidelines: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}