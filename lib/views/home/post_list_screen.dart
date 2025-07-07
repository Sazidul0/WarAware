import 'dart:io'; // Required for File
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/post_model.dart';
import '../../utils/enum.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/post_viewmodel.dart';
import '../auth/login_screen.dart';
import './create_post_screen.dart';
import './edit_post_screen.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  void _authListener() {
    final authViewModel = context.read<AuthViewModel>();
    final postViewModel = context.read<PostViewModel>();
    if (authViewModel.currentUser != null) {
      postViewModel.loadUserVotes(authViewModel.currentUser!.uid);
    } else {
      postViewModel.clearUserVotes();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostViewModel>().fetchPosts();
      final authViewModel = context.read<AuthViewModel>();
      if (authViewModel.currentUser != null) {
        context.read<PostViewModel>().loadUserVotes(authViewModel.currentUser!.uid);
      }
      authViewModel.addListener(_authListener);
    });
  }

  @override
  void dispose() {
    context.read<AuthViewModel>().removeListener(_authListener);
    super.dispose();
  }

  void _handleVote(Post post, int voteType) {
    final authViewModel = context.read<AuthViewModel>();
    if (authViewModel.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You must be logged in to vote.'),
          action: SnackBarAction(
            label: 'LOGIN',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ),
      );
    } else {
      context.read<PostViewModel>().vote(post, authViewModel.currentUser!.uid, voteType);
    }
  }

  void _navigateToCreatePost() {
    final authViewModel = context.read<AuthViewModel>();
    if (authViewModel.currentUser != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreatePostScreen()));
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen())).then((_) {
        final updatedAuthViewModel = context.read<AuthViewModel>();
        if (updatedAuthViewModel.currentUser != null && mounted) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreatePostScreen()));
        }
      });
    }
  }

  Future<void> _openLocationInMap(double latitude, double longitude) async {
    final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open map.')),
      );
    }
  }

  // NEW: Method to show the delete confirmation dialog
  Future<void> _showDeleteConfirmationDialog(int postId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Post?'),
          content: const SingleChildScrollView(
            child: Text('This action cannot be undone.'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('DELETE'),
              onPressed: () {
                context.read<PostViewModel>().deletePost(postId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final postViewModel = context.watch<PostViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(authViewModel.currentUser != null ? 'Hello, ${authViewModel.currentUser!.uname}' : 'Community Posts'),
        actions: [
          if (authViewModel.currentUser != null)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () => context.read<AuthViewModel>().logout(),
            ),
        ],
      ),
      // UPDATED: Body is now a Column to hold filters and the list
      body: Column(
        children: [
          _buildFilterChips(postViewModel),
          Expanded(child: _buildPostBody(authViewModel, postViewModel)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreatePost,
        tooltip: 'Create Post',
        child: const Icon(Icons.add),
      ),
    );
  }

  // NEW: Widget to build the filter chips at the top
  Widget _buildFilterChips(PostViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const SizedBox(width: 4),
            FilterChip(
              label: const Text('All'),
              selected: viewModel.activeFilter == null,
              onSelected: (_) => viewModel.applyFilter(null),
            ),
            const SizedBox(width: 8),
            FilterChip(
              avatar: Icon(Icons.healing, color: Colors.blue.shade700),
              label: const Text('Aid'),
              selected: viewModel.activeFilter == ZoneType.Aid,
              onSelected: (_) => viewModel.applyFilter(ZoneType.Aid),
            ),
            const SizedBox(width: 8),
            FilterChip(
              avatar: Icon(Icons.whatshot, color: Colors.red.shade700),
              label: const Text('Conflict'),
              selected: viewModel.activeFilter == ZoneType.Conflict,
              onSelected: (_) => viewModel.applyFilter(ZoneType.Conflict),
            ),
            const SizedBox(width: 8),
            FilterChip(
              avatar: Icon(Icons.shield, color: Colors.green.shade700),
              label: const Text('Safe'),
              selected: viewModel.activeFilter == ZoneType.Safe,
              onSelected: (_) => viewModel.applyFilter(ZoneType.Safe),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }


  Widget _buildPostBody(AuthViewModel authViewModel, PostViewModel postViewModel) {
    // UPDATED: Use the filtered list from the view model
    final posts = postViewModel.filteredPosts;

    if (postViewModel.isLoading && posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (postViewModel.errorMessage != null) {
      return Center(child: Text('Error: ${postViewModel.errorMessage}'));
    }

    // UPDATED: More descriptive empty state text
    if (posts.isEmpty) {
      return Center(
        child: Text(postViewModel.activeFilter != null
            ? 'No posts found for this zone.'
            : 'No posts yet. Be the first to create one!'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => postViewModel.fetchPosts(),
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          final userVote = postViewModel.userVotes[post.id];
          final isLiked = userVote == 1;
          final isDisliked = userVote == -1;

          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            clipBehavior: Clip.antiAlias, // Ensures image respects card border radius
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // NEW: Display the image if it exists
                if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                  Image.file(
                    File(post.imageUrl!),
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    // Show a fallback icon if the image fails to load
                    errorBuilder: (context, error, stackTrace) => const SizedBox(
                      height: 200,
                      child: Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey)),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.description, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('By: ${post.uname} • Zone: ${post.zoneType.name}', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      // Location Info Row (unchanged)
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Lat: ${post.latitude.toStringAsFixed(4)}, Lon: ${post.longitude.toStringAsFixed(4)}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.map_outlined),
                            iconSize: 20,
                            color: Theme.of(context).primaryColor,
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Open in Map',
                            onPressed: () => _openLocationInMap(post.latitude, post.longitude),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      // Vote and Action Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(isLiked ? Icons.thumb_up : Icons.thumb_up_outlined),
                                color: isLiked ? Colors.green : Colors.grey.shade700,
                                onPressed: () => _handleVote(post, 1),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined),
                                color: isDisliked ? Colors.red : Colors.grey.shade700,
                                onPressed: () => _handleVote(post, -1),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.verified_user_outlined, color: Colors.blue, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                post.verificationScore.toStringAsFixed(0),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                              // NEW: Conditional Edit/Delete Menu
                              if (authViewModel.currentUser?.uid == post.uid)
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      Navigator.of(context).push(MaterialPageRoute(
                                        builder: (_) => EditPostScreen(post: post),
                                      ));
                                    } else if (value == 'delete') {
                                      _showDeleteConfirmationDialog(post.id!);
                                    }
                                  },
                                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                    const PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
                                    const PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
                                  ],
                                )
                              else
                                const SizedBox(width: 48), // Keep spacing consistent if menu isn't there
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}