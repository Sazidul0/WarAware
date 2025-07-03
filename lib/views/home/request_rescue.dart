import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/rescue_model.dart';
import '../../viewmodels/rescue_viewmodel.dart';

class RequestRescueScreen extends StatefulWidget {
  const RequestRescueScreen({super.key});

  @override
  State<RequestRescueScreen> createState() => _RequestRescueScreenState();
}

class _RequestRescueScreenState extends State<RequestRescueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _locationTextController = TextEditingController();

  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  Position? _currentPosition;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _locationTextController.dispose();
    super.dispose();
  }

  // --- THIS IS THE FULLY IMPLEMENTED LOCATION METHOD ---
  Future<void> _getCurrentLocation() async {
    try {
      // 1. Check if location services are enabled on the device.
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      // 2. Check for location permissions.
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Request permissions if they are denied.
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      // 3. Handle the case where permissions are permanently denied.
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied, we cannot request permissions.');
      }

      // 4. If permissions are granted, get the current position.
      _currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      // If any error occurs, show it in a SnackBar.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not get location: ${e.toString()}")),
        );
      }
    }
    // Update the UI after attempting to get the location.
    if(mounted) {
      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    final XFile? selectedImage = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (selectedImage != null) {
      setState(() { _imageFile = selectedImage; });
    }
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate() && !_isSubmitting) {
      // The crucial check that was failing before
      if (_currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot submit without location. Please enable permissions and try again.')));
        return;
      }

      setState(() { _isSubmitting = true; });

      final newRequest = Rescue(
        message: _messageController.text.trim(),
        locationText: _locationTextController.text.trim(),
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        imageUrl: _imageFile?.path,
        timestamp: DateTime.now(),
      );

      final success = await context.read<RescueViewModel>().submitRequest(newRequest);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rescue request submitted successfully!')),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to submit request. Please try again.')),
          );
        }
        setState(() { _isSubmitting = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Rescue')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(labelText: 'Emergency Message', hintText: 'e.g., Person injured, requires medical aid.'),
                validator: (v) => v!.isEmpty ? 'Message cannot be empty' : null,
                maxLines: 4,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _locationTextController,
                decoration: const InputDecoration(labelText: 'Location Details', hintText: 'e.g., Near the main park entrance.'),
                validator: (v) => v!.isEmpty ? 'Location details are required' : null,
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(_imageFile == null ? 'Add Photo (Optional)' : 'Change Photo'),
                onPressed: _pickImage,
              ),
              if (_imageFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(_imageFile!.path), height: 150, fit: BoxFit.cover)),
                ),
              const SizedBox(height: 30),
              _isSubmitting
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('SUBMIT REQUEST'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: _submitRequest,
              ),
            ],
          ),
        ),
      ),
    );
  }
}