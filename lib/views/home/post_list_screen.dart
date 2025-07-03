import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/post_viewmodel.dart';
import '../auth/login_screen.dart';
import './create_post_screen.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch posts when the screen is first loaded
    // Using a post-frame callback ensures context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostViewModel>().fetchPosts();
    });
  }

  void _navigateToCreatePost() {
    final authViewModel = context.read<AuthViewModel>();

    if (authViewModel.currentUser != null) {
      // User is logged in, go straight to create post screen
      Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreatePostScreen())
      );
    } else {
      // User is not logged in, show login screen.
      // After login screen is popped (on success), the .then() block runs.
      Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LoginScreen())
      ).then((_) {
        // Re-check the login status after returning from the login flow
        final updatedAuthViewModel = context.read<AuthViewModel>();
        if (updatedAuthViewModel.currentUser != null && mounted) {
          // If login was successful, now navigate to the create post screen
          Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreatePostScreen())
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch both view models to rebuild UI on changes
    final authViewModel = context.watch<AuthViewModel>();
    final postViewModel = context.watch<PostViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(authViewModel.currentUser != null
            ? 'Hello, ${authViewModel.currentUser!.uname}'
            : 'Community Posts'),
        actions: [
          if (authViewModel.currentUser != null)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () {
                context.read<AuthViewModel>().logout();
              },
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
    // Show a loader only when loading for the first time
    if (viewModel.isLoading && viewModel.posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null) {
      return Center(child: Text('Error: ${viewModel.errorMessage}'));
    }

    if (viewModel.posts.isEmpty) {
      return const Center(
        child: Text('No posts yet. Be the first to create one!'),
      );
    }

    // Use RefreshIndicator to allow pull-to-refresh
    return RefreshIndicator(
      onRefresh: () => viewModel.fetchPosts(),
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: viewModel.posts.length,
        itemBuilder: (context, index) {
          final post = viewModel.posts[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16.0),
              title: Text(post.description, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                    'By: ${post.uname}  •  Zone: ${post.zoneType.name}\nStatus: ${post.postStatus.name}'),
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}