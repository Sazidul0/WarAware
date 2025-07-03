import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/post_viewmodel.dart';
import '../auth/login_screen.dart';
import './create_post_screen.dart';
import '../../models/post_model.dart';
import 'package:url_launcher/url_launcher.dart';



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

  // NEW: Method to launch the map application
  Future<void> _openLocationInMap(double latitude, double longitude) async {
    // This universal URL works on both iOS and Android to open the default map app.
    final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      // Show an error if the map can't be opened
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open map.')),
        );
      }
    }
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
      body: _buildPostBody(postViewModel),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreatePost,
        tooltip: 'Create Post',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPostBody(PostViewModel viewModel) {
    if (viewModel.isLoading && viewModel.posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null) {
      return Center(child: Text('Error: ${viewModel.errorMessage}'));
    }

    if (viewModel.posts.isEmpty) {
      return const Center(child: Text('No posts yet. Be the first to create one!'));
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.fetchPosts(),
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: viewModel.posts.length,
        itemBuilder: (context, index) {
          final post = viewModel.posts[index];
          final int? userVote = viewModel.userVotes[post.id];
          final bool isLiked = userVote == 1;
          final bool isDisliked = userVote == -1;

          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post Description
                  Text(post.description, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),

                  // Author and Zone Info
                  Text('By: ${post.uname} • Zone: ${post.zoneType.name}', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 8),

                  // --- NEW: Location Information Row ---
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          // Format the coordinates to 4 decimal places for cleanliness
                          'Lat: ${post.latitude.toStringAsFixed(4)}, Lon: ${post.longitude.toStringAsFixed(4)}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Add a button to open maps
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

                  // Divider
                  const Divider(height: 16),

                  // Vote and Score Row
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
                          const SizedBox(width: 8),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}