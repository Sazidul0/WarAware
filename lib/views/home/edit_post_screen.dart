import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../utils/enum.dart';
import '../../viewmodels/post_viewmodel.dart';

class EditPostScreen extends StatefulWidget {
  final Post post;
  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late ZoneType _selectedZoneType;
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Pre-fill the form fields with the existing post data
    _descriptionController = TextEditingController(text: widget.post.description);
    _selectedZoneType = widget.post.zoneType;
    if (widget.post.imageUrl != null) {
      _imageFile = XFile(widget.post.imageUrl!);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
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

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      // Create an updated Post object with new and old data
      final updatedPost = Post(
        id: widget.post.id,
        uid: widget.post.uid,
        uname: widget.post.uname,
        time: widget.post.time,
        postStatus: widget.post.postStatus,
        verificationScore: widget.post.verificationScore,
        latitude: widget.post.latitude,
        longitude: widget.post.longitude,
        // Get updated values from the form
        description: _descriptionController.text.trim(),
        zoneType: _selectedZoneType,
        imageUrl: _imageFile?.path,
      );

      await context.read<PostViewModel>().updatePost(updatedPost);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 6,
                validator: (value) => value!.trim().isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<ZoneType>(
                value: _selectedZoneType,
                decoration: const InputDecoration(labelText: 'Zone Type'),
                items: ZoneType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.name))).toList(),
                onChanged: (newValue) => setState(() => _selectedZoneType = newValue!),
              ),
              const SizedBox(height: 20),
              // Image Picker UI (identical to create_post_screen)
              _imageFile == null
                  ? OutlinedButton.icon(
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Change Image (Optional)'),
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
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveChanges,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}