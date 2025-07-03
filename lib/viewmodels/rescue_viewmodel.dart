import 'package:flutter/material.dart';
import '../models/rescue_model.dart';
import '../services/database_helper.dart';

class RescueViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Rescue> _rescues = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Rescue> get rescues => _rescues;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchRescues() async {
    _isLoading = true;
    notifyListeners();
    try {
      _rescues = await _dbHelper.getAllRescues();
    } catch (e) {
      _errorMessage = "Failed to load rescue requests: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitRequest(Rescue rescue) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _dbHelper.insertRescue(rescue);
      _rescues.insert(0, rescue); // Add to local list for immediate display
      return true;
    } catch (e) {
      _errorMessage = "Failed to submit request: $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}