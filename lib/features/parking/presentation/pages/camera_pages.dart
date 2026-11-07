import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/app_bottom_nav.dart';
import '../../../../widgets/parkops_app_bar.dart';
import '../../domain/entities/camera_inference_result.dart';
import '../providers/parking_providers.dart';

const _cameraId = 'opentopia-17916';
final _cameraPageUri = Uri.parse(
  'https://www.opentopia.com/webcam/17916?viewmode=livevideo',
);

class CameraPages extends ConsumerWidget {
  const CameraPages({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inference = ref.watch(cameraInferenceStreamProvider(_cameraId));

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: const ParkOpsAppBar(
        section: 'Camera',
        title: 'Parking Lot Camera',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          _cameraCard(context),
          const SizedBox(height: 16),
          _inferenceResults(inference),
          const SizedBox(height: 14),
          const _ProcessingNote(),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  Widget _cameraCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 190,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videocam, size: 44, color: Colors.white),
                SizedBox(height: 8),
                Text(
                  'Osaka, Japan',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Parking with Apartment View',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Public camera feed from Opentopia',
            style: TextStyle(fontSize: 12, color: AppColors.mist),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openCameraPage(context),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open live feed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCameraPage(BuildContext context) async {
    final opened = await launchUrl(
      _cameraPageUri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the camera feed.')),
      );
    }
  }

  Widget _inferenceResults(AsyncValue<CameraInferenceResult?> inference) {
    return inference.when(
      loading: () => const _ResultMessage(
        icon: Icons.hourglass_empty,
        message: 'Waiting for the first cloud inference result.',
      ),
      error: (error, _) => _ResultMessage(
        icon: Icons.error_outline,
        message: 'Could not load camera results: $error',
      ),
      data: (result) {
        if (result == null) {
          return const _ResultMessage(
            icon: Icons.cloud_queue,
            message: 'No inference result yet. The cloud worker runs once per minute.',
          );
        }
        return _resultCards(result);
      },
    );
  }

  Widget _resultCards(CameraInferenceResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10, left: 2),
          child: Text(
            'Latest AI detection',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _CountCard(
                value: result.vehicleCount,
                label: 'Vehicles detected',
                color: AppColors.full,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CountCard(
                value: result.emptySpaceCount,
                label: 'Empty spaces detected',
                color: AppColors.teal,
              ),
            ),
          ],
        ),
        if (result.processedAt != null) ...[
          const SizedBox(height: 8),
          Text(
            'Last processed ${_formatTime(result.processedAt!)}',
            style: const TextStyle(fontSize: 11, color: AppColors.mist),
          ),
        ],
      ],
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.navy),
          ),
        ],
      ),
    );
  }
}

class _ResultMessage extends StatelessWidget {
  const _ResultMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.navy),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: AppColors.navy),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessingNote extends StatelessWidget {
  const _ProcessingNote();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Counts are detections from the latest sampled frame, not confirmed '
      'availability for individual parking bays.',
      style: TextStyle(fontSize: 11, color: AppColors.mist, height: 1.4),
    );
  }
}

String _formatTime(DateTime time) {
  final local = time.toLocal();
  final date =
      '${local.year}-${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$date $hour:$minute';
}
