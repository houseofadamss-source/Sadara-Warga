import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'faq_screen.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback? onBack; // Tambahin callback buat back
  const ProfileScreen({super.key, required this.userData, this.onBack});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isNikVisible = false;
  late Map<String, dynamic> _user;

  @override
  void initState() {
    super.initState();
    _user = widget.userData;
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

  String _formatWhatsApp(String hp) {
    String clean = hp.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.startsWith('0')) {
      return '+62${clean.substring(1)}';
    } else if (clean.startsWith('62')) {
      return '+$clean';
    }
    return '+$clean';
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
              widget.onBack!(); // Balik ke tab 0 lewat callback
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
            // --- TOP CONTAINER (FOTO, NAMA, EMAIL, WA, EDIT BUTTON) ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Column(
                children: [
                  // Foto Profil
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
                  
                  // Nama Warga
                  Text(
                    _user['nama_lengkap'] ?? 'Nama Warga',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark),
                  ),
                  const SizedBox(height: 8),
                  
                  // Email & WhatsApp Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            _user['email'] ?? '-',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.circle, size: 4, color: Colors.grey),
                        ),
                        Text(
                          _formatWhatsApp(_user['nomor_hp'] ?? ''),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Edit Profile Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EditProfileScreen(userData: {
                            'nama': _user['nama_lengkap'] ?? '',
                            'hp': _user['nomor_hp'] ?? '',
                            'alamat': _user['alamat'] ?? '',
                            'nik': _user['nik'] ?? '',
                            'foto': _user['foto_profil'] ?? '',
                          })),
                        );
                        if (result == true) _refreshData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Edit Profil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // --- BOTTOM CONTAINER (NIK & ALAMAT) ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Column(
                children: [
                  // NIK Section
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
                  
                  // Alamat Section
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
            
            // --- MENU TILES ---
            _buildSettingsTile(context, Icons.settings_outlined, 'Pengaturan', () {
               Navigator.push(context, MaterialPageRoute(builder: (c) => SettingsScreen(userName: _user['nama_lengkap'] ?? 'Warga', userNik: _user['nik'] ?? '-')));
            }),
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

  Widget _buildSettingsTile(BuildContext context, IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
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
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
        trailing: isDestructive ? null : const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFCBD5E1)),
      ),
    );
  }
}
