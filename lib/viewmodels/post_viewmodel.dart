import 'package:flutter/material.dart';
import '../models/post_model.dart';
// You will need to create this DatabaseHelper class
import '../services/database_helper.dart';

class PostViewModel extends ChangeNotifier {
  List<Post> _posts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  PostViewModel() {
    // Fetch posts when the ViewModel is created
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Assumes DatabaseHelper is a singleton or has a static instance
      _posts = await DatabaseHelper.instance.getAllPosts();
    } catch (e) {
      _errorMessage = 'Failed to load posts: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPost(Post post) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newPost = await DatabaseHelper.instance.insertPost(post);
      _posts.add(newPost);
    } catch (e) {
      _errorMessage = 'Failed to add post: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePost(Post post) async {
    try {
      await DatabaseHelper.instance.updatePost(post);
      // Find and update the post in the local list
      final index = _posts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        _posts[index] = post;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to update post: $e';
      notifyListeners();
    }
  }

  Future<void> deletePost(int id) async {
    try {
      await DatabaseHelper.instance.deletePost(id);
      _posts.removeWhere((post) => post.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete post: $e';
      notifyListeners();
    }
  }
}