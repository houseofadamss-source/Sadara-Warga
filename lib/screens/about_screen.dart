import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF0F766E);
    const Color textDark = Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
        title: const Text('TENTANG APLIKASI', style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Image.asset(
                      'assets/images/Logo.png',
                      height: 80,
                      width: 80,
                      errorBuilder: (c, e, s) => const Icon(Icons.home_work_rounded, size: 64, color: primaryTeal),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Sadara Warga', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark)),
                  const Text('"Ruang Sapa & Kemudahan Bertetangga"', style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: primaryTeal)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Text('v1.0.0 (Stable)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildSection('VISI & MISI', 'Mewujudkan lingkungan Kp. Sinagar RT 003 RW 006 Desa Cihideung Udik yang modern, transparan, dan terhubung secara digital.\n\n• Mempercepat akses layanan persuratan warga.\n• Meningkatkan transparansi pengelolaan dana kas lingkungan.\n• Menyebarkan informasi kegiatan warga secara real-time.\n• Mendukung pertumbuhan ekonomi tetangga melalui direktori UMKM.'),
            const SizedBox(height: 32),
            _buildSection('DESKRIPSI', 'Sadara Warga (Sistem Administrasi dan Pelaporan Warga) adalah platform digital eksklusif yang dirancang khusus untuk memenuhi kebutuhan warga di Kp. Sinagar RT 003 RW 006. Aplikasi ini lahir dari inisiatif untuk mempererat tali silaturahmi serta menciptakan pelayanan wilayah yang lebih praktis, efisien, dan terbuka bagi seluruh elemen masyarakat.\n\nDengan Sadara Warga, kini urusan laporan kerusakan fasilitas umum, pengajuan surat pengantar, hingga memantau transparansi saldo kas RT dapat dilakukan hanya dalam satu genggaman.'),
            const SizedBox(height: 32),
            _buildSection('INFORMASI TEKNIS', '• Dikembangkan Oleh: Tim Sinagar Official\n• Basis Data: Supabase Cloud Service (Encrypted & Secure)\n• Rilis Terakhir: Juni 2026'),
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Mari bersama membangun wilayah yang lebih baik. Kritik dan saran pengembangan aplikasi sangat kami harapkan untuk kenyamanan bersama.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.5),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1.1)),
        const SizedBox(height: 12),
        Text(content, style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), height: 1.6)),
      ],
    );
  }
}
