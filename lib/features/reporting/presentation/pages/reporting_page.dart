import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import 'fill_the_report_page.dart';

import 'package:url_launcher/url_launcher.dart';

class ReportingPage extends StatelessWidget {
  const ReportingPage({super.key});

  Future<void> _openWhatsApp(BuildContext context) async {
    final Uri whatsappUrl = Uri.parse('https://wa.me/628122600960');

    try {
      final bool launched = await launchUrl(
        whatsappUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka WhatsApp.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan saat membuka WhatsApp.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text(
          'Reporting',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
        ),
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.navy,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            const Text(
              'Need Assistance?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose how you want to report a parking issue '
              'or contact our customer service.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF8493A3),
              ),
            ),
            const SizedBox(height: 28),

            // First option: Fill the Report
            _ReportingOption(
              icon: Icons.description_outlined,
              title: 'Fill the Report',
              subtitle: 'Submit a parking issue or complaint',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FillTheReportPage()),
                );
              },
              showArrow: true,
            ),

            const SizedBox(height: 16),

            _ReportingOption(
              icon: Icons.chat_outlined,
              title: 'WhatsApp Contact',
              subtitle: 'Contact ParkOps customer service',
              onTap: () => _openWhatsApp(context),
              showArrow: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportingOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showArrow;

  const _ReportingOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE6EDF3)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6EDF3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 25, color: const Color(0xFF477AA5)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Color(0xFF8493A3),
                      ),
                    ),
                  ],
                ),
              ),
              if (showArrow)
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Color(0xFF477AA5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
