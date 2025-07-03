import 'package:flutter/material.dart';
import '../models/first_aid_guideline_model.dart';
import '../services/database_helper.dart';

class FirstAidViewModel extends ChangeNotifier {
  List<FirstAidGuideline> _guidelines = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<FirstAidGuideline> get guidelines => _guidelines;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  FirstAidViewModel() {
    fetchGuidelines();
  }

  Future<void> fetchGuidelines() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _guidelines = await DatabaseHelper.instance.getAllGuidelines();
    } catch (e) {
      _errorMessage = 'Failed to load guidelines: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

// Add methods for add/update/delete if needed
}