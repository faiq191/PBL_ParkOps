import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../theme/app_colors.dart';
import '../providers/profile_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _emailController;
  late TextEditingController _nimController;
  final ImagePicker _picker = ImagePicker();
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    final user = ref.read(profileProvider);
    _nameController = TextEditingController(text: user.name);
    _bioController = TextEditingController(text: user.bio);
    _emailController = TextEditingController(text: user.email);
    _nimController = TextEditingController(text: user.nim);
    _avatarPath = user.avatarPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _nimController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _avatarPath = picked.path);
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.navy),
              title: const Text(
                'Choose from gallery',
                style: TextStyle(color: AppColors.navy),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: AppColors.navy),
              title: const Text(
                'Take a photo',
                style: TextStyle(color: AppColors.navy),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_avatarPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Remove photo',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() => _avatarPath = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Center(
      child: GestureDetector(
        onTap: _showImageOptions,
        child: Stack(
          children: [
            CircleAvatar(
              radius: 52,
              backgroundColor: AppColors.line,
              backgroundImage:
                  _avatarPath != null ? FileImage(File(_avatarPath!)) : null,
              child: _avatarPath == null
                  ? const Icon(Icons.person, size: 52, color: AppColors.mist)
                  : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.paper, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navy),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: AppColors.navy),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(profileProvider.notifier).updateProfile(
                    ref.read(profileProvider).copyWith(
                          name: _nameController.text,
                          bio: _bioController.text,
                          email: _emailController.text,
                          nim: _nimController.text,
                          avatarPath: _avatarPath,
                        ),
                  );
              Navigator.pop(context);
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppColors.teal,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          _buildAvatar(),
          const SizedBox(height: 24),
          _buildTextField('Name', _nameController),
          const SizedBox(height: 16),
          _buildTextField('NIM', _nimController),
          const SizedBox(height: 16),
          _buildTextField('Email', _emailController),
          const SizedBox(height: 16),
          _buildTextField('Bio', _bioController),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.mist,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.navy),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.teal),
            ),
          ),
        ),
      ],
    );
  }
}