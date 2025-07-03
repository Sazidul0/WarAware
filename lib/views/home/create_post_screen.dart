import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../utils/enum.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/post_viewmodel.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  ZoneType _selectedZoneType = ZoneType.Safe;

  // State variables for location
  Position? _currentPosition;
  String _locationMessage = "Fetching location...";
  bool _isFetchingLocation = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isFetchingLocation = true;
      _locationMessage = "Fetching location...";
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied, we cannot request permissions.');
      }

      _currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _locationMessage = "Location Acquired!";
    } catch (e) {
      _currentPosition = null;
      _locationMessage = "Could not get location: ${e.toString()}";
    } finally {
      setState(() {
        _isFetchingLocation = false;
      });
    }
  }

  Future<void> _submitPost() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      if (_currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot create post without location. Please enable permissions and try again.')),
        );
        return;
      }

      final authViewModel = context.read<AuthViewModel>();
      final postViewModel = context.read<PostViewModel>();
      final currentUser = authViewModel.currentUser!;

      final newPost = Post(
        uid: currentUser.uid,
        uname: currentUser.uname,
        time: DateTime.now(),
        zoneType: _selectedZoneType,
        description: _descriptionController.text.trim(),
        postStatus: PostStatus.Unverified,
        verificationScore: 0.0,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );

      await postViewModel.addPost(newPost);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post created successfully!')));
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'What\'s happening?', alignLabelWithHint: true),
                maxLines: 6,
                validator: (value) => value!.trim().isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<ZoneType>(
                value: _selectedZoneType,
                decoration: const InputDecoration(labelText: 'Select Zone Type'),
                items: ZoneType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.name))).toList(),
                onChanged: (newValue) => setState(() => _selectedZoneType = newValue!),
              ),
              const SizedBox(height: 20),
              // Location Information Widget
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    if (_isFetchingLocation)
                      const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 3)),
                    if (!_isFetchingLocation && _currentPosition != null)
                      const Icon(Icons.location_on, color: Colors.green),
                    if (!_isFetchingLocation && _currentPosition == null)
                      const Icon(Icons.location_off, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_locationMessage, style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (_currentPosition != null)
                            Text('Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, Lon: ${_currentPosition!.longitude.toStringAsFixed(4)}'),
                        ],
                      ),
                    ),
                    if (!_isFetchingLocation && _currentPosition == null)
                      IconButton(icon: const Icon(Icons.refresh), onPressed: _getCurrentLocation)
                  ],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submitPost,
                child: const Text('Submit Post'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}