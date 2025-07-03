import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../views/auth/login_screen.dart';
import './home/post_list_screen.dart';

import './home/first_aid_screen.dart'; // <-- Import the new screen
import './home/create_post_screen.dart'; // <-- Import create post screen

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
                // --- NEW: First Aid Guidelines Button ---
                ElevatedButton.icon(
                  icon: const Icon(Icons.medical_services_outlined),
                  label: const Text('First Aid Guidelines'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal, // A different color to stand out
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FirstAidScreen()),
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
                    final authViewModel = context.read<AuthViewModel>();
                    if (authViewModel.currentUser != null) {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreatePostScreen())); // Go to Create Post
                    } else {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
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