import 'package:flutter/material.dart';
import 'faq_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String userName;
  final String userNik;
  const SettingsScreen({super.key, required this.userName, required this.userNik});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifEnabled = false;

  void _showComingSoon(String title, String desc) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(children: [const Icon(Icons.info_outline, color: Colors.blue), const SizedBox(width: 12), Text(title, style: const TextStyle(fontSize: 16))]),
        content: Text(desc, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('MENGERTI', style: TextStyle(fontWeight: FontWeight.bold)))]
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color textDark = Color(0xFF1E293B);
    const Color primaryTeal = Color(0xFF0F766E);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
        title: const Text('PENGATURAN', style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('KEAMANAN & NOTIFIKASI'),
            _buildSettingTile(
              icon: Icons.notifications_active_outlined, color: Colors.orange,
              title: 'Notifikasi Aplikasi', sub: 'Fitur aktif di pembaruan selanjutnya.',
              trailing: Switch(value: _notifEnabled, onChanged: (v) => _showComingSoon('Notifikasi', 'Fitur notifikasi real-time sedang dalam tahap pengembangan sistem pusat.'), activeColor: primaryTeal),
            ),
            _buildSettingTile(
              icon: Icons.lock_outline_rounded, color: Colors.blue,
              title: 'Ubah Kata Sandi', sub: 'Amankan akun Anda secara berkala.',
              onTap: () => _showComingSoon('Ubah Sandi', 'Untuk saat ini perubahan kata sandi hanya dapat dilakukan melalui Admin RT demi validasi data keamanan.'),
            ),
            
            const SizedBox(height: 32),
            _buildSectionHeader('DUKUNGAN & INFORMASI'),
            _buildSettingTile(
              icon: Icons.help_outline_rounded, color: Colors.teal,
              title: 'Bantuan (FAQ)', sub: 'Panduan penggunaan aplikasi & layanan.',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => FaqScreen(userName: widget.userName, userNik: widget.userNik))),
            ),
            _buildSettingTile(
              icon: Icons.info_outline_rounded, color: Colors.indigo,
              title: 'Tentang Aplikasi', sub: 'Sadara Warga v1.0.0 (RT 03/06)',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AboutScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Padding(padding: const EdgeInsets.only(left: 4, bottom: 12), child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1)));

  Widget _buildSettingTile({required IconData icon, required Color color, required String title, required String sub, Widget? trailing, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
        subtitle: Text(sub, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFFCBD5E1)),
      ),
    );
  }
}
