import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../utils/enum.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/post_viewmodel.dart';
import 'dart:io'; // Required for File type
import 'package:image_picker/image_picker.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  ZoneType _selectedZoneType = ZoneType.Safe;

  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Position? _currentPosition;
  String _locationMessage = "Fetching location...";
  bool _isFetchingLocation = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
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

  Future<void> _pickImage(ImageSource source) async {
    final XFile? selectedImage = await _picker.pickImage(source: source, imageQuality: 80);
    if (selectedImage != null) {
      setState(() {
        _imageFile = selectedImage;
      });
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Photo Library'),
                  onTap: () {
                    _pickImage(ImageSource.gallery);
                    Navigator.of(context).pop();
                  }),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitPost() async {
    if (_formKey.currentState!.validate()) {
      if (_currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot create post without location.')));
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
        imageUrl: _imageFile?.path, // Pass the image file path or null
        postStatus: PostStatus.Unverified,
        verificationScore: 0.0,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );

      await postViewModel.addPost(newPost);

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
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
              // Image Picker UI
              _imageFile == null
                  ? OutlinedButton.icon(
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Add Image (Optional)'),
                onPressed: _showImagePickerOptions,
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Image Attached:', style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(_imageFile!.path), width: double.infinity, height: 200, fit: BoxFit.cover),
                      ),
                      IconButton(
                        icon: const CircleAvatar(backgroundColor: Colors.black54, child: Icon(Icons.close, color: Colors.white)),
                        onPressed: () => setState(() => _imageFile = null),
                      )
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Location Information Widget (unchanged)
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