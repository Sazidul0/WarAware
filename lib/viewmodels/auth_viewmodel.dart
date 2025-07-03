import 'dart:convert'; // For utf8
import 'package:crypto/crypto.dart'; // For sha256
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../../services/database_helper.dart';

class AuthViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Helper function to hash the password
  String _hashPassword(String password) {
    final bytes = utf8.encode(password); // Encode password to bytes
    final digest = sha256.convert(bytes); // Hash the bytes
    return digest.toString(); // Return the hash as a string
  }

  // Method to sign up a new user
  Future<bool> signUp({required String uname, required String password, String? occupation}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final existingUser = await _dbHelper.getUserByUsername(uname);
      if (existingUser != null) {
        throw ('Username "$uname" is already taken.');
      }

      final hashedPassword = _hashPassword(password);

      final newUser = User(
        uid: DateTime.now().millisecondsSinceEpoch.toString(),
        uname: uname,
        passwordHash: hashedPassword, // Store the HASH, not the password
        isAdmin: false,
        isVerified: false,
        occupation: occupation,
      );

      await _dbHelper.insertUser(newUser);
      _currentUser = newUser; // Automatically log in after signup
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Method to log in an existing user
  Future<bool> login({required String uname, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _dbHelper.getUserByUsername(uname);
      if (user == null) {
        throw ('Invalid username or password.'); // Generic error
      }

      // Hash the entered password and compare it with the stored hash
      final hashedPassword = _hashPassword(password);
      if (user.passwordHash != hashedPassword) {
        throw ('Invalid username or password.'); // Generic error
      }

      _currentUser = user;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}