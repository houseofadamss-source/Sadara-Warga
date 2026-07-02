import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../announcements/presentation/pages/admin_announcement_management_page.dart';
import '../../../announcements/presentation/pages/add_announcement_page.dart';
import '../../../surat/presentation/pages/surat_preview_debug_page.dart';
import '../../../citizen_management/presentation/pages/admin_verifikasi_page.dart';
import '../../../events/presentation/pages/admin_events_page.dart';
import '../../../finance/presentation/pages/admin_financial_report_page.dart';
import '../../../finance/presentation/pages/admin_manage_iuran_page.dart';
import '../../../finance/presentation/pages/admin_verifikasi_iuran_page.dart';
import '../../../reports/presentation/pages/admin_laporan_page.dart';
import '../../../sos/presentation/pages/admin_emergency_management_page.dart';
import '../../../umkm/presentation/pages/admin_umkm_management_page.dart';
import '../../../surat/presentation/pages/admin_manage_surat_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  String _userName = 'Admin';

  @override
  void initState() {
    super.initState();
    _loadAdminName();
  }

  Future<void> _loadAdminName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('cached_user_name') ?? 'Administrator';
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF0F766E);
    const Color textDark = Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
        title: const Text('ADMIN CONSOLE', style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Selamat Datang,', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    Text(_userName, style: const TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 24)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: primaryTeal, size: 28),
                )
              ],
            ),
            const SizedBox(height: 40),
            
            const Text('MANAJEMEN WILAYAH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1)),
            const SizedBox(height: 16),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildMenuTile(
                  icon: Icons.person_add_rounded, color: Colors.amber, 
                  title: 'Verifikasi Warga', sub: 'Cek pendaftar baru',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminVerifikasiPage())),
                ),
                _buildMenuTile(
                  icon: Icons.payments_rounded, color: Colors.green, 
                  title: 'Cek Iuran', sub: 'Validasi bukti bayar',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminVerifikasiIuranPage())),
                ),
                _buildMenuTile(
                  icon: Icons.assignment_rounded, color: Colors.orange, 
                  title: 'Laporan Masuk', sub: 'Tindak lanjuti aduan',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminLaporanPage())),
                ),
                _buildMenuTile(
                  icon: Icons.mark_as_unread_rounded, color: Colors.indigo, 
                  title: 'Manajemen Surat', sub: 'Proses surat pengantar',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminManageSuratPage())),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            const Text('PUBLIKASI & KONTEN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1)),
            const SizedBox(height: 16),
            
            _buildActionTile(
              icon: Icons.add_comment_rounded, color: Colors.blue,
              title: 'Buat Pengumuman', sub: 'Kirim info & berita terbaru ke warga',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AddAnnouncementPage())),
            ),
            _buildActionTile(
              icon: Icons.history_rounded, color: Colors.teal,
              title: 'Kelola Pengumuman', sub: 'Liat history & hapus postingan',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminAnnouncementManagementPage())),
            ),
            _buildActionTile(
              icon: Icons.picture_as_pdf_rounded, color: Colors.deepOrange,
              title: 'Cek Design Surat (DEBUG)', sub: 'Lihat pratinjau PDF & QR Code',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SuratPreviewDebugPage())),
            ),
            _buildActionTile(
              icon: Icons.event_available_rounded, color: Colors.redAccent,
              title: 'Agenda Kegiatan', sub: 'Atur jadwal acara & cek RSVP',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminEventsPage())),
            ),
            _buildActionTile(
              icon: Icons.storefront_rounded, color: Colors.teal,
              title: 'Etalase UMKM', sub: 'Validasi & kelola usaha warga',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminUmkmManagementPage())),
            ),
            
            const SizedBox(height: 40),
            const Text('SISTEM & KEUANGAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1)),
            const SizedBox(height: 16),

            _buildActionTile(
              icon: Icons.pie_chart_rounded, color: Colors.pinkAccent,
              title: 'Laporan Kas RT', sub: 'Catat pengeluaran & update saldo',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminFinancialReportPage())),
            ),
            _buildActionTile(
              icon: Icons.settings_applications_rounded, color: Colors.blueGrey,
              title: 'Pengaturan Iuran', sub: 'Buat tagihan sampah, kas, dll',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminManageIuranPage())),
            ),
            _buildActionTile(
              icon: Icons.emergency_share_rounded, color: Colors.red,
              title: 'Kontak Darurat', sub: 'Atur nomor polisi, medis, damkar',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminEmergencyManagementPage())),
            ),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({required IconData icon, required Color color, required String title, required String sub, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 24)),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
            const SizedBox(height: 4),
            Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({required IconData icon, required Color color, required String title, required String sub, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
      ),
    );
  }
}
