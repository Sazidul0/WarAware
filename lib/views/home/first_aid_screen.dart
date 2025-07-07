import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/first_aid_viewmodel.dart';

class FirstAidScreen extends StatelessWidget {
  const FirstAidScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use .watch to listen for changes and rebuild the UI
    final viewModel = context.watch<FirstAidViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('First Aid Guidelines'),
      ),
      body: _buildBody(viewModel),
    );
  }

  Widget _buildBody(FirstAidViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null) {
      return Center(child: Text('Error: ${viewModel.errorMessage}'));
    }

    if (viewModel.guidelines.isEmpty) {
      return const Center(child: Text('No guidelines found.'));
    }

    // Use ListView.builder for an efficient, scrollable list
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: viewModel.guidelines.length,
      itemBuilder: (context, index) {
        final guideline = viewModel.guidelines[index];
        // Use a Card for better visual separation
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            title: Text(
              guideline.problemName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            children: <Widget>[
              // This is the content that expands/collapses
              Container(
                color: Colors.black.withOpacity(0.03),
                padding: const EdgeInsets.all(16.0),
                alignment: Alignment.centerLeft,
                child: Text(guideline.problemDescription),
              ),
            ],
          ),
        );
      },
    );
  }
}