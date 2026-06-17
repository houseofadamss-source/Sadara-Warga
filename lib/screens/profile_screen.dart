import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'faq_screen.dart';
import 'welcome_screen.dart';
import 'changelog_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback? onBack; 
  const ProfileScreen({super.key, required this.userData, this.onBack});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isNikVisible = false;
  late Map<String, dynamic> _user;
  bool _hasUpdate = false;
  String _currentVersion = "";

  @override
  void initState() {
    super.initState();
    _user = widget.userData;
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;
      
      final data = await Supabase.instance.client
          .from('app_updates')
          .select('version_name')
          .order('version_code', ascending: false)
          .limit(1)
          .maybeSingle();

      if (data != null && mounted) {
        final latestVersion = data['version_name'];
        if (latestVersion != _currentVersion) {
          setState(() => _hasUpdate = true);
        }
      }
    } catch (e) { /* ignore */ }
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userData != oldWidget.userData) {
      setState(() {
        _user = widget.userData;
      });
    }
  }

  void _refreshData() async {
    final nik = _user['nik'];
    final data = await Supabase.instance.client
        .from('users')
        .select()
        .eq('nik', nik)
        .maybeSingle();
    
    if (data != null && mounted) {
      setState(() {
        _user = data;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  String _getMaskedNik(String nik) {
    if (nik.length < 16) return '****************';
    return '************${nik.substring(12)}';
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF0F766E);
    const Color textDark = Color(0xFF1E293B);
    const Color scaffoldBg = Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Profil Saya', style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 20),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!(); 
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryTeal.withValues(alpha: 0.1), width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: primaryTeal,
                      backgroundImage: (_user['foto_profil'] != null && _user['foto_profil'].isNotEmpty)
                          ? NetworkImage(_user['foto_profil'])
                          : null,
                      child: (_user['foto_profil'] == null || _user['foto_profil'].isEmpty)
                          ? const Icon(Icons.person, size: 55, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _user['nama_lengkap'] ?? 'Nama Warga',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _user['email'] ?? '-',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                         final Map<String, String> stringUser = _user.map((key, value) => MapEntry(key, value?.toString() ?? ''));
                         Navigator.push(context, MaterialPageRoute(builder: (c) => EditProfileScreen(userData: stringUser))).then((_) => _refreshData());
                      },
                      icon: const Icon(Icons.edit_note_rounded, size: 20),
                      label: const Text('EDIT PROFIL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.badge_outlined, color: primaryTeal, size: 22),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Nomor NIK', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                              const SizedBox(height: 2),
                              Text(
                                _isNikVisible ? (_user['nik'] ?? '-') : _getMaskedNik(_user['nik'] ?? ''),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark, letterSpacing: 1),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _isNikVisible = !_isNikVisible),
                          icon: Icon(
                            _isNikVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: const Color(0xFFCBD5E1),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFF1F5F9)),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.location_on_outlined, color: primaryTeal, size: 22),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Alamat Lengkap', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                              const SizedBox(height: 4),
                              Text(
                                _user['alamat'] ?? '-',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDark, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSettingsTile(context, Icons.settings_outlined, 'Pengaturan', () {
               Navigator.push(context, MaterialPageRoute(builder: (c) => SettingsScreen(userName: _user['nama_lengkap'] ?? 'Warga', userNik: _user['nik'] ?? '-')));
            }),
            const SizedBox(height: 12),
            _buildSettingsTile(
              context, 
              Icons.system_update_rounded, 
              'Versi Aplikasi', 
              () {
                setState(() => _hasUpdate = false);
                Navigator.push(context, MaterialPageRoute(builder: (c) => const ChangelogScreen()));
              },
              showBadge: _hasUpdate,
              trailingText: "v$_currentVersion",
            ),
            const SizedBox(height: 12),
            _buildSettingsTile(context, Icons.help_outline_rounded, 'Pusat Bantuan', () {
               Navigator.push(context, MaterialPageRoute(builder: (c) => FaqScreen(userName: _user['nama_lengkap'] ?? 'Warga', userNik: _user['nik'] ?? '-')));
            }),
            const SizedBox(height: 12),
            _buildSettingsTile(context, Icons.logout_rounded, 'Keluar Akun', () => _showLogoutDialog(), isDestructive: true),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Keluar Akun?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Anda perlu masuk kembali untuk mengakses layanan Sadara Warga.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('BATAL', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(c);
              _logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('KELUAR'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, IconData icon, String title, VoidCallback onTap, {bool isDestructive = false, bool showBadge = false, String? trailingText}) {
    const Color primaryTeal = Color(0xFF0F766E);
    const Color textDark = Color(0xFF1E293B);
    final Color iconColor = isDestructive ? Colors.red : primaryTeal;
    final Color textColor = isDestructive ? Colors.red : textDark;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: isDestructive ? Colors.red.withValues(alpha: 0.05) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Row(
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
            if (showBadge) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              ),
            ]
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingText != null) Text(trailingText, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(width: 4),
            if (!isDestructive) const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}
