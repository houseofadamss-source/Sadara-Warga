import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FaqScreen extends StatelessWidget {
  final String userName;
  final String userNik;
  const FaqScreen({super.key, required this.userName, required this.userNik});

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF0F766E);
    const Color textDark = Color(0xFF1E293B);

    final List<Map<String, dynamic>> faqs = [
      {
        'category': 'MANAJEMEN AKUN & PRIVASI',
        'questions': [
          {
            'q': 'Mengapa NIK saya tidak ditemukan saat registrasi?',
            'a': 'Sistem kami hanya menerima NIK yang sudah terdata secara resmi di basis data wilayah RT 03/06. Jika Anda warga baru, silakan temui Pak RT untuk pendataan manual.'
          },
          {
            'q': 'Apakah data Foto KK saya aman?',
            'a': 'Foto KK hanya digunakan oleh Admin untuk validasi satu kali. Data disimpan dalam storage terenkripsi dan tidak dapat dilihat oleh warga lain.'
          },
        ]
      },
      {
        'category': 'PELAYANAN SURAT & DOKUMEN',
        'questions': [
          {
            'q': 'Apa itu "Surat Pengantar RT Online"?',
            'a': 'Fitur untuk memangkas waktu pengisian blangko. Setelah isi form, Pak RT akan memberi nomor surat secara digital. Anda tinggal datang untuk tanda tangan basah dan cap.'
          },
          {
            'q': 'Berapa lama proses persetujuan surat?',
            'a': 'Admin biasanya memproses dalam 1-3 jam (tergantung kesibukan). Cek status di menu "Aktivitas" untuk mengetahui jika surat sudah siap.'
          },
        ]
      },
      {
        'category': 'KEUANGAN & TRANSPARANSI',
        'questions': [
          {
            'q': 'Bagaimana jika saya salah upload bukti iuran?',
            'a': 'Segera hubungi Pak RT. Admin akan menolak pengajuan dengan keterangan tertentu, lalu Anda bisa mengunggah ulang bukti yang benar di menu Iuran.'
          },
          {
            'q': 'Siapa yang bisa melihat Laporan Kas?',
            'a': 'Seluruh warga terverifikasi dapat melihat saldo real-time dan rincian penggunaan dana wilayah melalui link Google Sheets yang disediakan.'
          },
        ]
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
        title: const Text('PUSAT BANTUAN', style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100), // Tambah padding bawah agar tidak tertutup nav bar
              itemCount: faqs.length,
              itemBuilder: (context, index) {
                final cat = faqs[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 16, top: 8),
                      child: Text(cat['category'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1.1)),
                    ),
                    ... (cat['questions'] as List).map((f) => _buildFaqTile(f['q'], f['a'], primaryTeal)),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
          _buildContactSection(primaryTeal),
        ],
      ),
    );
  }

  Widget _buildFaqTile(String q, String a, Color primary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: ExpansionTile(
        shape: const Border(),
        title: Text(q, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        expandedAlignment: Alignment.topLeft,
        children: [Text(a, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5))],
      ),
    );
  }

  Widget _buildContactSection(Color primary) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const Text('Masih butuh bantuan?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          const Text('Hubungi Pak RT untuk kendala teknis atau data.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 56,
            child: ElevatedButton.icon(
              onPressed: () async {
                const String phone = '6281585058720'; // Nomor Pak RT Fix
                final String msg = 'Halo Pak RT, saya $userName (NIK: $userNik) ingin bertanya mengenai...';
                final url = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(msg)}");
                if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.chat_bubble_rounded),
              label: const Text('HUBUNGI ADMIN RT', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
            ),
          ),
        ],
      ),
    );
  }
}
