import 'package:flutter/material.dart';

import 'homepage.dart';

class AppColors {
  static const navy = Color(0xFF0F1B2D);
  static const amber = Color(0xFFFDB833);
  static const mist = Color(0xFFAEB9C7);
  static const paper = Color(0xFFEDF1F5);
  static const ok = Color(0xFF3FA796);
  static const full = Color(0xFFD96C5B);
  static const teal = Color(0xFF0E7C6B);
  static const tealLight = Color(0xFF2FB79B);
  static const tealSoft = Color(0xFFE1F1EC);
  static const line = Color(0xFFE6EAF0);
}

class CameraPages extends StatefulWidget {
  const CameraPages({super.key});

  @override
  State<CameraPages> createState() => _CameraPagesState();
}

class _CameraPagesState extends State<CameraPages> {
  bool _detectionOverlay = true;
  int _navIndex = 1; // 0=Home, 1=Camera, 2=Map, 3=Info

  void _onNavTap(int i) {
    if (i == _navIndex) return;
    if (i == 0) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomepagePages()),
      );
    }
    // TODO: 2 = Map, 3 = Info — halamannya belum dibuat
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Camera',
              style: TextStyle(fontSize: 11, color: AppColors.mist),
            ),
            SizedBox(height: 2),
            Text(
              'Parking Lot Camera',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
                actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromARGB(255, 24, 25, 25), // teal terang (kiri atas)
                    Color.fromARGB(60, 20, 12, 92), // teal gelap (kanan bawah)
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.local_parking, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          _cameraCard(),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(
                child: _StatCard(
                  value: '18',
                  label: 'Available',
                  color: AppColors.teal,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  value: '30',
                  label: 'Occupied',
                  color: AppColors.full,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  value: '48',
                  label: 'Total bays',
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _infoCard(),
          const SizedBox(height: 16),
          _mapButton(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        height: 68,
        backgroundColor: AppColors.paper,
        indicatorColor: const Color(0xFFDDE4EC),
        onDestinationSelected: _onNavTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.videocam_outlined),
            selectedIcon: Icon(Icons.videocam),
            label: 'Camera',
          ),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.info_outline), label: 'Info'),
        ],
      ),
    );
  }

  // ===== Kartu kamera: header "Camera 01" + gambar dummy + toggle =====
  Widget _cameraCard() {
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
                const Text(
                  'Camera 01',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
          _DummyCameraFeed(showOverlay: _detectionOverlay),
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
                  value: _detectionOverlay,
                  activeColor: AppColors.navy,
                  onChanged: (v) => setState(() => _detectionOverlay = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== Kartu info delay kamera =====
  Widget _infoCard() {
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
              const Icon(Icons.sync, color: AppColors.navy, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Camera delayed by 1 minute',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ),
              const Text(
                '99.2%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Counts reflect the camera feed from 1 minute ago. Outlined bays show available and occupied spaces.',
            style: TextStyle(fontSize: 11, color: AppColors.mist, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ===== Tombol navy "Find a space on the map" =====
  Widget _mapButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          // TODO: navigate ke map_pages
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          children: const [
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

// ===== Dummy "feed" kamera: kotak gelap + bays + badge, UI doang =====
class _DummyCameraFeed extends StatelessWidget {
  final bool showOverlay;
  const _DummyCameraFeed({required this.showOverlay});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        color: const Color(0xFF4A4F55), // warna aspal
        child: Stack(
          children: [
            // garis lajur tengah
            Center(
              child: Container(
                height: 2,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
            if (showOverlay)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _Bay(occupied: true)),
                        const SizedBox(width: 10),
                        Expanded(child: _Bay(occupied: true)),
                        const SizedBox(width: 10),
                        Expanded(child: _Bay(occupied: false)),
                        const SizedBox(width: 10),
                        Expanded(child: _Bay(occupied: true)),
                        const SizedBox(width: 10),
                        Expanded(child: _Bay(occupied: false)),
                        const SizedBox(width: 10),
                        Expanded(child: _Bay(occupied: true)),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: _Bay(occupied: false)),
                        const SizedBox(width: 10),
                        Expanded(child: _Bay(occupied: true)),
                        const SizedBox(width: 10),
                        Expanded(child: _Bay(occupied: true)),
                        const SizedBox(width: 10),
                        Expanded(child: _Bay(occupied: false)),
                        const SizedBox(width: 10),
                        Expanded(child: _Bay(occupied: false)),
                        const SizedBox(width: 10),
                        Expanded(child: _Bay(occupied: true)),
                      ],
                    ),
                  ],
                ),
              ),
            // badge "1 min delay" kiri atas
            Positioned(
              top: 10,
              left: 10,
              child: _pill(
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 6, color: Color(0xFF7FD8C8)),
                    SizedBox(width: 6),
                    Text(
                      '1 min delay',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
            // tombol fullscreen kanan atas
            Positioned(
              top: 10,
              right: 10,
              child: _pill(
                square: true,
                child: const Icon(
                  Icons.fullscreen,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            // label kiri bawah
            Positioned(
              bottom: 10,
              left: 10,
              child: _pill(
                child: const Text(
                  'CAM 01  /  TODAY 09:11:11',
                  style: TextStyle(color: Colors.white, fontSize: 9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill({required Widget child, bool square = false}) {
    return Container(
      padding: square
          ? const EdgeInsets.all(6)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(square ? 8 : 999),
      ),
      child: child,
    );
  }
}

// ===== Satu kotak "parking bay" di gambar dummy =====
class _Bay extends StatelessWidget {
  final bool occupied;
  const _Bay({required this.occupied});

  @override
  Widget build(BuildContext context) {
    final Color bayLine = occupied
        ? const Color(0xFFF0B27A)
        : const Color(0xFF7FD8C8);
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: bayLine, width: 2),
        color: bayLine.withOpacity(0.15),
      ),
      child: occupied
          ? Padding(
              padding: const EdgeInsets.all(6),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade300, // "mobil"
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            )
          : null,
    );
  }
}

// ===== Kartu angka kecil (18 / 30 / 48) =====
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.mist),
          ),
        ],
      ),
    );
  }
}
