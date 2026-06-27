import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../injection_container.dart';
import '../../domain/repositories/version_repository.dart';
import 'changelog_page.dart';
import 'about_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifEnabled = false;
  bool _hasUpdate = false;
  String _currentVersion = "";

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _currentVersion = packageInfo.version;
        });
      }
      
      final result = await sl<VersionRepository>().getChangelog();
      result.fold(
        (l) => null,
        (list) {
          if (list.isNotEmpty && mounted) {
            final latestVersion = list[0].versionName;
            if (latestVersion != _currentVersion) {
              setState(() => _hasUpdate = true);
            }
          }
        }
      );
    } catch (e) { /* ignore */ }
  }

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
              trailing: Switch(value: _notifEnabled, onChanged: (v) => _showComingSoon('Notifikasi', 'Fitur notifikasi real-time sedang dalam tahap pengembangan sistem pusat.'), activeThumbColor: primaryTeal),
            ),
            _buildSettingTile(
              icon: Icons.lock_outline_rounded, color: Colors.blue,
              title: 'Ubah Kata Sandi', sub: 'Amankan akun Anda secara berkala.',
              onTap: () => _showComingSoon('Ubah Sandi', 'Untuk saat ini perubahan kata sandi hanya dapat dilakukan melalui Admin RT demi validasi data keamanan.'),
            ),
            
            const SizedBox(height: 32),
            _buildSectionHeader('DUKUNGAN & INFORMASI'),
            _buildSettingTile(
              icon: Icons.system_update_rounded, color: Colors.indigo,
              title: 'Versi Aplikasi', sub: 'Sadara Warga v$_currentVersion',
              showBadge: _hasUpdate,
              onTap: () {
                setState(() => _hasUpdate = false);
                Navigator.push(context, MaterialPageRoute(builder: (c) => const ChangelogPage()));
              },
            ),
            _buildSettingTile(
              icon: Icons.info_outline_rounded, color: Colors.blueGrey,
              title: 'Tentang Aplikasi', sub: 'Informasi pengembang & lisensi.',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AboutPage())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Padding(padding: const EdgeInsets.only(left: 4, bottom: 12), child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1)));

  Widget _buildSettingTile({required IconData icon, required Color color, required String title, required String sub, Widget? trailing, VoidCallback? onTap, bool showBadge = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 20)),
        title: Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
            if (showBadge) ...[
              const SizedBox(width: 8),
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
            ]
          ],
        ),
        subtitle: Text(sub, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFFCBD5E1)),
      ),
    );
  }
}
