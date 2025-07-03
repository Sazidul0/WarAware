import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../views/auth/login_screen.dart';
import './home/post_list_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade300, Colors.indigo.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.shield,
                  size: 100,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Community Safety',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 50),
                // Button to view all posts
                ElevatedButton.icon(
                  icon: const Icon(Icons.article_outlined),
                  label: const Text('View All Posts'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PostListScreen()),
                    );
                  },
                ),
                const SizedBox(height: 20),
                // Button to Login or Create a Post
                OutlinedButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text('Login / Create Post'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white, width: 2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    // This logic handles whether to show login or go to create post
                    final authViewModel = context.read<AuthViewModel>();
                    if (authViewModel.currentUser != null) {
                      // Already logged in, so we can skip login
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const PostListScreen()));
                    } else {
                      // Not logged in, go to login screen
                      Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LoginScreen()));
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}