import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_announcement_screen.dart';
import 'admin_verifikasi_screen.dart';
import 'admin_laporan_screen.dart';
import 'admin_kelola_pengumuman_screen.dart';
import 'admin_verifikasi_iuran_screen.dart';
import 'admin_umkm_management_screen.dart';
import 'admin_events_screen.dart'; 
import 'admin_manage_iuran_screen.dart';
import 'admin_financial_report_screen.dart';
import 'admin_manage_surat_screen.dart'; // Import Baru

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _adminName = 'Admin';
  String _adminFoto = '';
  String _adminRole = '';

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final prefs = await SharedPreferences.getInstance();
    final nik = prefs.getString('userNik');
    if (nik != null) {
      final data = await Supabase.instance.client.from('users').select().eq('nik', nik).maybeSingle();
      if (data != null && mounted) {
        setState(() {
          _adminName = data['nama_lengkap'] ?? 'Admin';
          _adminFoto = data['foto_profil'] ?? '';
          _adminRole = (data['role'] ?? '').toString().toLowerCase();
        });

        if (_adminRole != 'super_admin') {
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF0F766E);
    const Color textDark = Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
        title: const Text('ADMIN CENTER', style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45, backgroundColor: primaryTeal,
                    backgroundImage: _adminFoto.isNotEmpty ? NetworkImage(_adminFoto) : null,
                    child: _adminFoto.isEmpty ? const Icon(Icons.person, size: 45, color: Colors.white) : null,
                  ),
                  const SizedBox(height: 16),
                  Text(_adminName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: Text(_adminRole.toUpperCase(), style: const TextStyle(color: primaryTeal, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),

            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PUSAT KONTROL RT', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
                  SizedBox(height: 8),
                  Text(
                    'Kelola pengumuman, verifikasi warga, hingga transparansi laporan keuangan wilayah Anda secara real-time di sini.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
                  ),
                ],
              ),
            ),

            _buildSectionHeader('KABAR & KEGIATAN'),
            _buildMenuTile(
              icon: Icons.add_comment_rounded, color: Colors.blue, 
              title: 'Buat Pengumuman', sub: 'Kirim info terbaru ke seluruh warga',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AddAnnouncementScreen())),
            ),
            _buildMenuTile(
              icon: Icons.history_rounded, color: Colors.teal, 
              title: 'Kelola Pengumuman', sub: 'Liat history & hapus postingan',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminKelolaPengumumanScreen())),
            ),
            _buildMenuTile(
              icon: Icons.event_note_rounded, color: Colors.indigo, 
              title: 'Kelola Acara', sub: 'Atur jadwal kegiatan warga & RSVP',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminEventsScreen())),
            ),

            const SizedBox(height: 24),

            _buildSectionHeader('LAYANAN & ADUAN'),
            _buildMenuTile(
              icon: Icons.mark_as_unread_rounded, color: Colors.indigo, 
              title: 'Manajemen Surat', sub: 'Proses pengajuan surat pengantar',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminManageSuratScreen())),
            ),
            _buildMenuTile(
              icon: Icons.person_add_rounded, color: Colors.amber, 
              title: 'Verifikasi Warga', sub: 'Cek pendaftar baru & foto KK',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminVerifikasiScreen())),
            ),
            _buildMenuTile(
              icon: Icons.assignment_rounded, color: Colors.orange, 
              title: 'Laporan Masuk', sub: 'Tindak lanjuti aduan warga',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminLaporanScreen())),
            ),
            _buildMenuTile(
              icon: Icons.store_mall_directory_rounded, color: Colors.purple, 
              title: 'Manajemen UMKM', sub: 'Verifikasi & pilih UMKM unggulan',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminUmkmManagementScreen())),
            ),

            const SizedBox(height: 24),

            _buildSectionHeader('KEUANGAN LINGKUNGAN'),
            _buildMenuTile(
              icon: Icons.payments_rounded, color: Colors.green, 
              title: 'Verifikasi Pembayaran', sub: 'Cek bukti transfer iuran warga',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminVerifikasiIuranScreen())),
            ),
            _buildMenuTile(
              icon: Icons.settings_applications_rounded, color: Colors.blueGrey, 
              title: 'Kelola Tagihan Iuran', sub: 'Buat iuran sampah, kematian, dll',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminManageIuranScreen())),
            ),
            _buildMenuTile(
              icon: Icons.pie_chart_rounded, color: Colors.pinkAccent, 
              title: 'Laporan Keuangan Kas', sub: 'Input pengeluaran & saldo kas RT',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminFinancialReportScreen())),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1.1)),
    );
  }

  Widget _buildMenuTile({required IconData icon, required Color color, required String title, required String sub, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
        subtitle: Text(sub, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFCBD5E1)),
      ),
    );
  }
}
