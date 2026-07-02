import 'package:flutter/material.dart';
import 'surat_form_page.dart';
import 'surat_history_page.dart';

class SuratMenuPage extends StatelessWidget {
  final String nik;
  final String nama;
  const SuratMenuPage({super.key, required this.nik, required this.nama});

  static const Color primaryTeal = Color(0xFF0F766E);
  static const Color textDark = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> services = [
      {
        'title': 'Surat Pengantar RT',
        'desc': 'Pengantar untuk keperluan ke Kelurahan/Kecamatan.',
        'icon': Icons.description_rounded,
        'color': Colors.blue,
        'isAvailable': true,
      },
      {
        'title': 'Kartu Keluarga (KK)',
        'desc': 'Persyaratan pembuatan atau pecah kartu keluarga.',
        'icon': Icons.groups_rounded,
        'color': Colors.orange,
        'isAvailable': false,
        'req': ['Fotocopy KK Lama', 'Fotocopy KTP', 'Surat Nikah/Akta Cerai', 'Surat Pindah (jika ada)']
      },
      {
        'title': 'KTP-el / KIA',
        'desc': 'Persyaratan rekam baru atau ganti KTP rusak.',
        'icon': Icons.badge_rounded,
        'color': Colors.purple,
        'isAvailable': false,
        'req': ['Fotocopy KK', 'KTP Lama (jika rusak)', 'Surat Kehilangan (jika hilang)']
      },
      {
        'title': 'Akta Kelahiran',
        'desc': 'Persyaratan pengurusan akta lahir anak.',
        'icon': Icons.child_care_rounded,
        'color': Colors.pink,
        'isAvailable': false,
        'req': ['Surat Kenal Lahir RS/Bidan', 'Fotocopy KK & KTP Orang Tua', 'Fotocopy Surat Nikah']
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
        title: const Text('LAYANAN SURAT', style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHistoryBanner(context),
            const SizedBox(height: 32),
            const Text('Pilih Layanan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 8),
            const Text('Silakan pilih jenis surat atau informasi persyaratan dokumen yang Anda butuhkan.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5)),
            const SizedBox(height: 32),
            ...services.map((s) => _buildServiceCard(context, s)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SuratHistoryPage())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [primaryTeal, Color(0xFF0D9488)]),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: primaryTeal.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: const Row(
          children: [
            Icon(Icons.history_edu_rounded, color: Colors.white, size: 32),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Riwayat & Status Surat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Cek progress & download PDF surat Anda', style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, Map<String, dynamic> s) {
    bool isAvailable = s['isAvailable'];

    return GestureDetector(
      onTap: () {
        if (isAvailable) {
          Navigator.push(context, MaterialPageRoute(builder: (c) => SuratFormPage(nik: nik, nama: nama, jenisSurat: s['title'])));
        } else {
          _showRequirements(context, s);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: s['color'].withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Icon(s['icon'], color: s['color'], size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textDark)),
                  const SizedBox(height: 4),
                  Text(s['desc'], style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: isAvailable ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(isAvailable ? 'AJUKAN ONLINE' : 'LIHAT SYARAT', style: TextStyle(color: isAvailable ? Colors.green : Colors.orange, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }

  void _showRequirements(BuildContext context, Map<String, dynamic> s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (c) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(s['icon'], color: s['color']),
                const SizedBox(width: 12),
                Text('Syarat ${s['title']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Dokumen yang harus disiapkan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            ...(s['req'] as List<String>).map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [const Icon(Icons.check_circle_outline, size: 16, color: Colors.green), const SizedBox(width: 8), Text(r, style: const TextStyle(fontSize: 14))]),
            )),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.withOpacity(0.1))),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 12),
                  Expanded(child: Text('Pengajuan online untuk dokumen ini masih dalam pengembangan. Silakan hubungi Pak RT untuk proses manual.', style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w500))),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
