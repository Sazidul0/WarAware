import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago; // Add timeago to pubspec.yaml for nice timestamps
import 'package:url_launcher/url_launcher.dart';
import '../../models/rescue_model.dart';
import '../../viewmodels/rescue_viewmodel.dart';
import 'dart:io';

class RescueListScreen extends StatefulWidget {
  const RescueListScreen({super.key});
  @override
  State<RescueListScreen> createState() => _RescueListScreenState();
}

class _RescueListScreenState extends State<RescueListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RescueViewModel>().fetchRescues();
    });
  }

  Future<void> _openLocationInMap(double lat, double lon) async {
    // ... (same as in PostListScreen)
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RescueViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Active Rescue Alerts')),
      body: RefreshIndicator(
        onRefresh: () => viewModel.fetchRescues(),
        child: viewModel.isLoading && viewModel.rescues.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : viewModel.rescues.isEmpty
            ? const Center(child: Text('No active rescue requests.'))
            : ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: viewModel.rescues.length,
          itemBuilder: (context, index) {
            final rescue = viewModel.rescues[index];
            return Card(
              elevation: 4,
              color: Colors.red.shade50,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (rescue.imageUrl != null)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.file(File(rescue.imageUrl!), width: double.infinity, height: 180, fit: BoxFit.cover),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rescue.message, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_pin, size: 16, color: Colors.black54),
                            const SizedBox(width: 4),
                            Expanded(child: Text(rescue.locationText, style: const TextStyle(color: Colors.black54))),
                            IconButton(icon: const Icon(Icons.map, color: Colors.blue), onPressed: () => _openLocationInMap(rescue.latitude, rescue.longitude)),
                          ],
                        ),
                        const Divider(),
                        Text(timeago.format(rescue.timestamp), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}