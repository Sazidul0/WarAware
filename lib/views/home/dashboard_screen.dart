import 'dart:io';

import 'package:ally/views/home/rescue_list_screen.dart';
// Updated import to point to your new TranslationScreen file
import '../home/translation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// ViewModels
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/post_viewmodel.dart';

// Models & Enums
import '../../models/post_model.dart';
import '../../utils/enum.dart';

// Screens
import '../auth/login_screen.dart';
import './create_post_screen.dart';
import './edit_post_screen.dart';
import './first_aid_screen.dart';
import './request_rescue.dart';

/// Placeholder screen for the 'Offline' button functionality.
class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline Mode')),
      body: Container(
        color: Colors.grey[850],
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Offline functionality will be implemented here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = context.read<AuthViewModel>();
      final postViewModel = context.read<PostViewModel>();
      postViewModel.fetchPosts();
      authViewModel.addListener(_authListener);
      if (authViewModel.currentUser != null) {
        postViewModel.loadUserVotes(authViewModel.currentUser!.uid);
      }
    });
  }

  @override
  void dispose() {
    context.read<AuthViewModel>().removeListener(_authListener);
    super.dispose();
  }

  void _authListener() {
    if (mounted) {
      final authViewModel = context.read<AuthViewModel>();
      final postViewModel = context.read<PostViewModel>();
      if (authViewModel.currentUser != null) {
        postViewModel.loadUserVotes(authViewModel.currentUser!.uid);
      } else {
        postViewModel.clearUserVotes();
      }
      setState(() {});
    }
  }

  void _navigateToCreatePost() {
    final authViewModel = context.read<AuthViewModel>();
    if (authViewModel.currentUser != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreatePostScreen()));
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final postViewModel = context.watch<PostViewModel>();

    return Scaffold(
      endDrawer: _buildUserDrawer(context, authViewModel),
      body: Column(
        children: [
          _buildHeader(context, authViewModel),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => postViewModel.fetchPosts(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildGridMenu(context)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('Recent Updates', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          if(postViewModel.activeFilter != null)
                            TextButton(onPressed: () => postViewModel.applyFilter(null), child: const Text("Show All"))
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildFilterChips(postViewModel)),
                  _buildPostBody(authViewModel, postViewModel),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomAppBar(context),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreatePost,
        tooltip: 'Create Post',
        child: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader(BuildContext context, AuthViewModel authViewModel) {
    return Builder(
      builder: (context) => Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16.0,
          left: 20.0,
          right: 20.0,
          bottom: 16.0,
        ),
        color: Colors.indigo,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authViewModel.currentUser?.uname ?? 'Ally',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
                ),
                const SizedBox(height: 4),
                Text(
                  authViewModel.currentUser != null ? 'Community Member' : 'Dashboard',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                if (authViewModel.currentUser != null) {
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RescueListScreen())
                  );
                } else {
                  // User not logged in - navigate to rescue list
                }
              },
              child: authViewModel.currentUser != null
                  ? Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.notifications_active,
                  size: 24,
                  color: Colors.blue.shade800,
                ),
              )
                  : const SizedBox.shrink(),
            ),
            GestureDetector(
              onTap: () {
                if (authViewModel.currentUser != null) {
                  Scaffold.of(context).openEndDrawer();
                } else {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
                }
              },
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blue.shade100,
                child: authViewModel.currentUser != null
                    ? const Icon(Icons.person, color: Colors.indigo, size: 28)
                    : const Icon(Icons.login, color: Colors.indigo, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Drawer? _buildUserDrawer(BuildContext context, AuthViewModel authViewModel) {
    if (authViewModel.currentUser == null) return null;
    final user = authViewModel.currentUser!;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user.uname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            accountEmail: Text(user.uname.toUpperCase() ?? 'Welcome!'), // Changed to user.email for correctness
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(user.uname.substring(0, 1).toUpperCase(), style: const TextStyle(fontSize: 24, color: Colors.indigo)),
            ),
            decoration: const BoxDecoration(color: Colors.indigo),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.of(context).pop();
              context.read<AuthViewModel>().logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGridMenu(BuildContext context) {
    Widget buildGridItem(IconData icon, String label, Color color, VoidCallback onTap) {
      return Card(
        elevation: 2.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 10),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    final postViewModel = context.read<PostViewModel>();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
        children: [
          buildGridItem(Icons.healing, 'Aid Posts', Colors.blue.shade700, () => postViewModel.applyFilter(ZoneType.Aid)),
          buildGridItem(Icons.whatshot, 'Conflict Posts', Colors.red.shade700, () => postViewModel.applyFilter(ZoneType.Conflict)),
          buildGridItem(Icons.shield, 'Safe Zones', Colors.green.shade700, () => postViewModel.applyFilter(ZoneType.Safe)),
          buildGridItem(Icons.sos, 'Request Rescue', Colors.orange.shade800, () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RequestRescueScreen()));
          }),
        ],
      ),
    );
  }

  BottomAppBar _buildBottomAppBar(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          TextButton.icon(
            icon: const Icon(Icons.medical_services_outlined),
            label: const Text('First Aid'),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FirstAidScreen())),
          ),
          const SizedBox(width: 40), // The space for the notch
          TextButton.icon(
            icon: const Icon(Icons.cloud_off_outlined),
            label: const Text('Offline'),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OfflineScreen())),
          ),
        ],
      ),
    );
  }

  void _handleVote(Post post, int voteType) {
    final authViewModel = context.read<AuthViewModel>();
    if (authViewModel.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You must be logged in to vote.'),
          action: SnackBarAction(label: 'LOGIN', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()))),
        ),
      );
    } else {
      context.read<PostViewModel>().vote(post, authViewModel.currentUser!.uid, voteType);
    }
  }

  Future<void> _openLocationInMap(double latitude, double longitude) async {
    final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open map.')));
    }
  }

  Future<void> _showDeleteConfirmationDialog(int postId) async {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text('This action cannot be undone.'),
        actions: <Widget>[
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(dialogContext).pop()),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
            onPressed: () {
              context.read<PostViewModel>().deletePost(postId);
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(PostViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Text('Aid'),
              avatar: Icon(Icons.healing, color: Colors.blue.shade700),
              selected: viewModel.activeFilter == ZoneType.Aid,
              onSelected: (_) => viewModel.applyFilter(ZoneType.Aid),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Conflict'),
              avatar: Icon(Icons.whatshot, color: Colors.red.shade700),
              selected: viewModel.activeFilter == ZoneType.Conflict,
              onSelected: (_) => viewModel.applyFilter(ZoneType.Conflict),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Safe'),
              avatar: Icon(Icons.shield, color: Colors.green.shade700),
              selected: viewModel.activeFilter == ZoneType.Safe,
              onSelected: (_) => viewModel.applyFilter(ZoneType.Safe),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostBody(AuthViewModel authViewModel, PostViewModel postViewModel) {
    final posts = postViewModel.filteredPosts;

    if (postViewModel.isLoading && posts.isEmpty) {
      return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
    }
    if (postViewModel.errorMessage != null) {
      return SliverFillRemaining(child: Center(child: Text('Error: ${postViewModel.errorMessage}')));
    }
    if (posts.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              postViewModel.activeFilter != null ? 'No posts found for this filter.' : 'No posts yet. Be the first!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final post = posts[index];
          final userVote = postViewModel.userVotes[post.id];
          final isLiked = userVote == 1;
          final isDisliked = userVote == -1;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            child: Card(
              elevation: 3,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                    Image.file(
                      File(post.imageUrl!),
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(height: 200, child: Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey))),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ==================== THIS IS THE UPDATED SECTION ====================
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                post.description,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.translate, color: Colors.blueAccent),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                // This navigates to your new screen, passing the required data
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TranslationScreen(
                                      description: post.description,
                                      username: post.uname,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        // =====================================================================

                        const SizedBox(height: 8),
                        Text('By: ${post.uname} • Zone: ${post.zoneType.name}', style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
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
                                if (authViewModel.currentUser?.uid == post.uid)
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditPostScreen(post: post)));
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
                                  const SizedBox(width: 48),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        childCount: posts.length,
      ),
    );
  }
}