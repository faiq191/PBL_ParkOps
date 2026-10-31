import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../theme/app_colors.dart';

class FillTheReportPage extends StatefulWidget {
  const FillTheReportPage({super.key});

  @override
  State<FillTheReportPage> createState() => _FillTheReportPageState();
}

class _FillTheReportPageState extends State<FillTheReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String? _reportType;
  XFile? _selectedImage;
  bool _isSubmitting = false;

  final List<String> _reportTypes = [
    'Parking area issue',
    'Other',
  ];

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1600,
      );

      if (!mounted || image == null) return;

      setState(() {
        _selectedImage = image;
      });
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to select the image. Please try again.'),
        ),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _submitReport() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_reportType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a report type.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // TODO: Connect this form to the report backend/database.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Form validated. Report submission is not connected yet.',
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontSize: 13,
        color: Color(0xFF9AA7B4),
      ),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE0E7ED),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE0E7ED),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF477AA5),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
          if (required)
            const Text(
              ' *',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text(
          'Fill the Report',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
        ),
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.navy,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              const Text(
                'Report a Problem',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tell us about the parking issue so our team '
                'can review it.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFF8493A3),
                ),
              ),
              const SizedBox(height: 26),

              // Report type
              _sectionLabel('Report Type', required: true),
              DropdownButtonFormField<String>(
                value: _reportType,
                isExpanded: true,
                decoration: _inputDecoration(
                  hintText: 'Select report type',
                  prefixIcon: const Icon(
                    Icons.report_problem_outlined,
                    color: Color(0xFF477AA5),
                  ),
                ),
                items: _reportTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(
                      type,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.navy,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _reportType = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a report type.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 22),

              // Parking location
              _sectionLabel('Parking Location', required: true),
              TextFormField(
                controller: _locationController,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDecoration(
                  hintText: 'e.g. Parking Area A, Level 1',
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF477AA5),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the parking location.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 22),

              // Description
              _sectionLabel('Description', required: true),
              TextFormField(
                controller: _descriptionController,
                minLines: 4,
                maxLines: 6,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDecoration(
                  hintText: 'Describe the issue in detail...',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe the issue.';
                  }
                  if (value.trim().length < 10) {
                    return 'Please enter at least 10 characters.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 14),

              // Photo upload
              _sectionLabel('Upload Photo (Optional)'),
              const Text(
                'Add a photo to help explain the parking issue.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8493A3),
                ),
              ),
              const SizedBox(height: 12),

              if (_selectedImage == null)
                InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 26,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFCCD9E4),
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 36,
                          color: Color(0xFF477AA5),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Choose Photo',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF477AA5),
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Select an image from your gallery',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8493A3),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      Image.file(
                        File(_selectedImage!.path),
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: IconButton(
                          onPressed: _removeImage,
                          tooltip: 'Remove photo',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.redAccent,
                          ),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: Colors.black54,
                          padding: const EdgeInsets.all(10),
                          child: const Text(
                            'Photo selected',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 30),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF477AA5),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF9AAFC1),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Report',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}