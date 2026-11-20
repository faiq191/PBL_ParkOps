import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../parking/domain/entities/parking_zone.dart';
import '../../../parking/presentation/providers/parking_providers.dart';
import '../providers/report_providers.dart';

class FillTheReportPage extends ConsumerStatefulWidget {
  const FillTheReportPage({super.key});

  @override
  ConsumerState<FillTheReportPage> createState() =>
      _FillTheReportPageState();
}

class _FillTheReportPageState extends ConsumerState<FillTheReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String? _reportType;
  String? _zoneId;
  XFile? _selectedImage;
  bool _isSubmitting = false;

  final List<String> _reportTypes = [
    'Parking area issue',
    'Other',
  ];

  @override
  void dispose() {
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

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final user = ref.read(authStateProvider).value;
    if (user == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please sign in to submit a report.')),
      );
      return;
    }

    ParkingZone? zone;
    for (final z in ref.read(zonesListProvider)) {
      if (z.id == _zoneId) zone = z;
    }
    if (zone == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select the parking lot.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(reportRepositoryProvider).submit(
            uid: user.uid,
            email: user.email,
            zoneId: zone.id,
            zoneName: zone.name,
            type: _reportType!,
            description: _descriptionController.text.trim(),
          );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not send the report. Please try again.'),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
    });
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          _selectedImage == null
              ? 'Report sent. Thank you!'
              : 'Report sent. Photo attachments are not uploaded yet.',
        ),
      ),
    );
    navigator.pop();
  }

  InputDecoration _inputDecoration({
    required String hintText,
    Widget? prefixIcon,
  }) {
    final palette = context.palette;
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 13,
        color: palette.mist,
      ),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: palette.card,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: palette.line,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: palette.line,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: palette.accent,
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
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.palette.navy,
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
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.paper,
      appBar: AppBar(
        title: Text(
          'Fill the Report',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: palette.navy,
          ),
        ),
        backgroundColor: palette.paper,
        foregroundColor: palette.navy,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Text(
                'Report a Problem',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: palette.navy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tell us about the parking issue so our team '
                'can review it.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: palette.mist,
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
                  prefixIcon: Icon(
                    Icons.report_problem_outlined,
                    color: palette.accent,
                  ),
                ),
                items: _reportTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(
                      type,
                      style: TextStyle(
                        fontSize: 13,
                        color: palette.navy,
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
              Consumer(
                builder: (context, ref, _) {
                  final zones = ref.watch(zonesListProvider);
                  final selected =
                      zones.any((z) => z.id == _zoneId) ? _zoneId : null;
                  return DropdownButtonFormField<String>(
                    value: selected,
                    isExpanded: true,
                    decoration: _inputDecoration(
                      hintText: zones.isEmpty
                          ? 'Loading parking lots...'
                          : 'Select parking lot',
                      prefixIcon: Icon(
                        Icons.location_on_outlined,
                        color: palette.accent,
                      ),
                    ),
                    items: zones.map((zone) {
                      return DropdownMenuItem<String>(
                        value: zone.id,
                        child: Text(
                          zone.name,
                          style: TextStyle(
                            fontSize: 13,
                            color: palette.navy,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: zones.isEmpty
                        ? null
                        : (value) {
                            setState(() {
                              _zoneId = value;
                            });
                          },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select the parking lot.';
                      }
                      return null;
                    },
                  );
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
              Text(
                'Add a photo to help explain the parking issue.',
                style: TextStyle(
                  fontSize: 12,
                  color: palette.mist,
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
                      color: palette.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: palette.line,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 36,
                          color: palette.accent,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Choose Photo',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: palette.accent,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Select an image from your gallery',
                          style: TextStyle(
                            fontSize: 11,
                            color: palette.mist,
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
                            backgroundColor: palette.card,
                            foregroundColor: Colors.redAccent,
                          ),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ),
                      const Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: ColoredBox(
                          color: Colors.black54,
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: Text(
                              'Photo selected',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
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
                    backgroundColor: palette.accent,
                    foregroundColor: Colors.white,
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