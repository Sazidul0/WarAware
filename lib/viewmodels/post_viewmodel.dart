import 'package:flutter/material.dart';
import '../models/post_model.dart';
// You will need to create this DatabaseHelper class
import '../services/database_helper.dart';
import '../utils/enum.dart';

class PostViewModel extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Post> _posts = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<int, int> _userVotes = {};

  // NEW: State for filtering
  ZoneType? _activeFilter;

  // --- Public Getters ---
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<int, int> get userVotes => _userVotes;

  /// Returns a list of posts, filtered by the active zone type if one is selected.
  List<Post> get filteredPosts {
    if (_activeFilter == null) {
      return _posts; // Return all posts if no filter is active
    }
    return _posts.where((post) => post.zoneType == _activeFilter).toList();
  }

  /// Getter for the active filter to highlight the button in the UI.
  ZoneType? get activeFilter => _activeFilter;

  // --- Core Data Methods ---

  Future<void> fetchPosts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _posts = await _dbHelper.getAllPosts();
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
      final newPost = await _dbHelper.insertPost(post);
      _posts.insert(0, newPost);
    } catch (e) {
      _errorMessage = 'Failed to add post: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates an existing post in the database and the local state.
  Future<void> updatePost(Post post) async {
    try {
      await _dbHelper.updatePost(post);
      final index = _posts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        _posts[index] = post;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = "Failed to update post: $e";
      notifyListeners();
    }
  }

  /// Deletes a post from the database and the local state.
  Future<void> deletePost(int postId) async {
    try {
      await _dbHelper.deletePost(postId);
      _posts.removeWhere((post) => post.id == postId);
      notifyListeners();
    } catch (e) {
      _errorMessage = "Failed to delete post: $e";
      notifyListeners();
    }
  }

  // --- NEW AND UPDATED METHODS ---

  /// Sets the active filter and notifies the UI to rebuild.
  void applyFilter(ZoneType? filter) {
    // If the user clicks the same filter again, turn it off.
    if (_activeFilter == filter) {
      _activeFilter = null;
    } else {
      _activeFilter = filter;
    }
    notifyListeners();
  }

  // --- NEW AND UPDATED METHODS FOR VOTING ---

  /// Fetches a user's votes from the database when they log in.
  Future<void> loadUserVotes(String userId) async {
    _userVotes = await _dbHelper.getVotesForUser(userId);
    notifyListeners();
  }

  /// Clears the user's votes from the state when they log out.
  void clearUserVotes() {
    _userVotes = {};
    notifyListeners();
  }

  /// The core logic for processing a user's vote on a post.
  Future<void> vote(Post post, String userId, int voteType) async {
    final int currentVote = _userVotes[post.id] ?? 0; // 0 if no current vote
    int scoreChange = 0;

    // Case 1: The user is toggling their vote off (e.g., un-liking)
    if (currentVote == voteType) {
      scoreChange = -voteType; // If un-liking a +1, score changes by -1. If un-disliking a -1, score changes by +1.
      await _dbHelper.removeVote(userId, post.id!);
      _userVotes.remove(post.id);
    }
    // Case 2: The user is changing their vote (e.g., from dislike to like)
    else if (currentVote != 0) {
      scoreChange = voteType * 2; // From -1 to +1 is a change of +2. From +1 to -1 is a change of -2.
      await _dbHelper.addOrUpdateVote(userId, post.id!, voteType);
      _userVotes[post.id!] = voteType;
    }
    // Case 3: The user is casting a new vote on this post
    else {
      scoreChange = voteType; // +1 for like, -1 for dislike
      await _dbHelper.addOrUpdateVote(userId, post.id!, voteType);
      _userVotes[post.id!] = voteType;
    }

    if (scoreChange != 0) {
      // Find the post in the local list and update its state immediately for a responsive UI
      final postIndex = _posts.indexWhere((p) => p.id == post.id);
      if (postIndex != -1) {
        final oldPost = _posts[postIndex];
        final updatedPost = Post(
          id: oldPost.id,
          uid: oldPost.uid,
          uname: oldPost.uname,
          time: oldPost.time,
          zoneType: oldPost.zoneType,
          description: oldPost.description,
          postStatus: oldPost.postStatus,
          // Apply the score change
          verificationScore: oldPost.verificationScore + scoreChange,
          latitude: oldPost.latitude,
          longitude: oldPost.longitude,
          imageUrl: oldPost.imageUrl,
          communityNotes: oldPost.communityNotes,
        );

        // Update the database in the background
        await _dbHelper.updatePost(updatedPost);

        // Update the local list and notify the UI
        _posts[postIndex] = updatedPost;
        notifyListeners();
      }
    }
  }
}