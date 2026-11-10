import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../routes.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/app_bottom_nav.dart';
import '../../../../widgets/parkops_app_bar.dart';
import '../../data/camera_feeds.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../domain/entities/camera_feed.dart';
import '../../domain/entities/camera_inference_result.dart';
import '../providers/parking_providers.dart';
import '../widgets/format_time.dart';
import '../widgets/lot_chips.dart';

class CameraPages extends ConsumerStatefulWidget {
  const CameraPages({super.key});

  @override
  ConsumerState<CameraPages> createState() => _CameraPagesState();
}

class _CameraPagesState extends ConsumerState<CameraPages> {
  Timer? _statusRefreshTimer;

  @override
  void initState() {
    super.initState();
    _statusRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _statusRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _setOverlay(bool enabled) async {
    final saved = await ref
        .read(cameraOverlayPreferenceProvider.notifier)
        .setEnabled(enabled);
    if (!mounted || saved) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Could not save the camera preference.')),
      );
  }

  Future<void> _openCameraPage(CameraFeed feed) async {
    final opened = await launchUrl(
      feed.pageUri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the camera feed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(selectedCameraFeedProvider);
    final inference = ref.watch(cameraInferenceStreamProvider(feed.id));
    final overlayEnabled = ref.watch(cameraOverlayPreferenceProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: const ParkOpsAppBar(
        section: 'Camera',
        title: 'Parking Lot Camera',
      ),
      body: _buildBody(feed, overlayEnabled, inference),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  Widget _buildBody(
    CameraFeed feed,
    bool overlayEnabled,
    AsyncValue<CameraInferenceResult?> inference,
  ) {
    final result = inference.asData?.value;
    final available = result?.emptySpaceCount;
    final occupied = result?.vehicleCount;
    final total = available == null || occupied == null
        ? null
        : available + occupied;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        _cameraCard(feed, overlayEnabled, inference),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: StatCard(
                value: available?.toString() ?? '--',
                label: 'Available',
                color: AppColors.teal,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                value: occupied?.toString() ?? '--',
                label: 'Occupied',
                color: AppColors.full,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                value: total?.toString() ?? '--',
                label: 'Total bays',
                color: AppColors.navy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _infoCard(result, inference),
        const SizedBox(height: 16),
        _mapButton(),
      ],
    );
  }

  Widget _cameraCard(
    CameraFeed feed,
    bool overlayEnabled,
    AsyncValue<CameraInferenceResult?> inference,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.videocam_outlined,
                  color: AppColors.navy,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: feed.id,
                      isExpanded: true,
                      isDense: true,
                      borderRadius: BorderRadius.circular(10),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.navy,
                      ),
                      items: [
                        for (final item in cameraFeeds)
                          DropdownMenuItem(
                            value: item.id,
                            child: Text(
                              item.title,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                      ],
                      onChanged: (id) {
                        if (id != null) {
                          ref
                              .read(selectedCameraIdProvider.notifier)
                              .select(id);
                        }
                      },
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Open camera feed',
                  onPressed: () => _openCameraPage(feed),
                  icon: const Icon(Icons.open_in_new, color: AppColors.navy),
                ),
              ],
            ),
          ),
          _InferenceCameraFeed(
            inference: inference,
            showOverlay: overlayEnabled,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: [
                const Text(
                  'Detection overlay',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: overlayEnabled,
                  activeTrackColor: AppColors.navy,
                  onChanged: _setOverlay,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(
    CameraInferenceResult? result,
    AsyncValue<CameraInferenceResult?> inference,
  ) {
    final processedAt = result?.processedAt;
    final age = processedAt == null
        ? null
        : DateTime.now().toUtc().difference(processedAt.toUtc());
    final isRecent = age != null && age <= const Duration(minutes: 2);

    final String heading;
    final String detail;
    final IconData icon;

    if (inference.hasError) {
      heading = 'Could not load detection data';
      detail = 'Check your connection and Firestore access, then try again.';
      icon = Icons.error_outline;
    } else if (result == null) {
      heading = 'Waiting for camera data';
      detail = 'Ask the laptop operator to start the ML worker.';
      icon = Icons.sync;
    } else if (!isRecent) {
      heading = 'Camera data is out of date';
      detail = 'Ask the laptop operator to start or check the ML worker.';
      icon = Icons.sync;
    } else {
      heading = 'Camera data updates automatically';
      detail =
          'Counts and the preview refresh whenever the laptop publishes a '
          'new result.';
      icon = Icons.sync;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.navy, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  heading,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            processedAt == null
                ? detail
                : '$detail Last update: ${formatTimestamp(processedAt)}.',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.mist,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pushReplacementNamed(Routes.map),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Row(
          children: [
            SizedBox(width: 6),
            Text(
              'Find a space on the map',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            Spacer(),
            Icon(Icons.map_outlined, size: 20),
            SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}

class _InferenceCameraFeed extends StatelessWidget {
  const _InferenceCameraFeed({
    required this.inference,
    required this.showOverlay,
  });

  final AsyncValue<CameraInferenceResult?> inference;
  final bool showOverlay;

  @override
  Widget build(BuildContext context) {
    final result = inference.asData?.value;
    final image = result?.framePreview;

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: ColoredBox(
        color: const Color(0xFF4A4F55),
        child: image == null
            ? const Center(
                child: Text(
                  'Waiting for the laptop ML worker',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(
                    image,
                    key: ValueKey(result?.processedAt),
                    fit: BoxFit.contain,
                    gaplessPlayback: false,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Text(
                        'Could not display the camera frame',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ),
                  if (showOverlay &&
                      result != null &&
                      result.frameWidth > 0 &&
                      result.frameHeight > 0)
                    CustomPaint(
                      painter: _DetectionOverlayPainter(
                        detections: result.detections,
                        frameWidth: result.frameWidth,
                        frameHeight: result.frameHeight,
                      ),
                    ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _feedPill(
                      Text(
                        result?.processedAt == null
                            ? 'WAITING FOR ML'
                            : 'UPDATED ${formatTimestamp(result!.processedAt!)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _DetectionOverlayPainter extends CustomPainter {
  const _DetectionOverlayPainter({
    required this.detections,
    required this.frameWidth,
    required this.frameHeight,
  });

  final List<CameraDetection> detections;
  final int frameWidth;
  final int frameHeight;

  @override
  void paint(Canvas canvas, Size size) {
    if (frameWidth <= 0 || frameHeight <= 0) return;
    final scale = (size.width / frameWidth).clamp(
      0.0,
      size.height / frameHeight,
    );
    final imageWidth = frameWidth * scale;
    final imageHeight = frameHeight * scale;
    final offsetX = (size.width - imageWidth) / 2;
    final offsetY = (size.height - imageHeight) / 2;

    for (final detection in detections) {
      if (detection.box.length != 4) continue;
      final rect = Rect.fromLTRB(
        offsetX + detection.box[0] * scale,
        offsetY + detection.box[1] * scale,
        offsetX + detection.box[2] * scale,
        offsetY + detection.box[3] * scale,
      );
      final color = detection.className.toLowerCase() == 'empty'
          ? const Color(0xFF7FD8C8)
          : const Color(0xFFF0B27A);
      canvas.drawRect(
        rect,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      final label =
          '${detection.className} '
          '${(detection.confidence * 100).round()}%';
      final text = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width);
      final labelTop = (rect.top - text.height - 4).clamp(0.0, size.height);
      final labelRect = Rect.fromLTWH(
        rect.left,
        labelTop,
        text.width + 8,
        text.height + 4,
      );
      canvas.drawRect(labelRect, Paint()..color = color);
      text.paint(canvas, Offset(labelRect.left + 4, labelRect.top + 2));
    }
  }

  @override
  bool shouldRepaint(_DetectionOverlayPainter oldDelegate) =>
      oldDelegate.detections != detections ||
      oldDelegate.frameWidth != frameWidth ||
      oldDelegate.frameHeight != frameHeight;
}

Widget _feedPill(Widget child) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0x8C000000),
      borderRadius: BorderRadius.circular(999),
    ),
    child: child,
  );
}
