import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'settings_screen.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback? onBack;
  final VoidCallback? onRefresh; 
  const ProfileScreen({super.key, required this.userData, this.onBack, this.onRefresh});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isNikVisible = false;
  late Map<String, dynamic> _user;
  bool _isUploading = false;

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
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      
      final data = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (data != null && mounted) {
        setState(() {
          _user = data;
        });
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_user_name', data['nama_lengkap'] ?? 'Warga');
        await prefs.setString('cached_user_foto', data['foto_profil'] ?? '');

        if (widget.onRefresh != null) widget.onRefresh!();
      }
    } catch (e) { /* ignore */ }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('GANTI FOTO PROFIL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1, color: Colors.grey)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                    child: _buildSourceCard(Icons.camera_alt_rounded, 'Kamera'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                    child: _buildSourceCard(Icons.photo_library_rounded, 'Galeri'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await picker.pickImage(source: source, imageQuality: 50);
    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      final file = File(pickedFile.path);
      final fileName = '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await client.storage.from('user_avatars').upload(fileName, file);
      final imageUrl = client.storage.from('user_avatars').getPublicUrl(fileName);
      await client.from('users').update({'foto_profil': imageUrl}).eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto profil berhasil diperbarui!'), backgroundColor: Color(0xFF0F766E)));
        _refreshData();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal upload: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _buildSourceCard(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF0F766E), size: 32),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
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
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryTeal.withValues(alpha: 0.1), width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: primaryTeal.withValues(alpha: 0.05),
                          backgroundImage: (_user['foto_profil'] != null && _user['foto_profil'].toString().isNotEmpty)
                              ? NetworkImage(_user['foto_profil'])
                              : null,
                          child: (_user['foto_profil'] == null || _user['foto_profil'].toString().isEmpty)
                              ? const Icon(Icons.person, size: 55, color: primaryTeal)
                              : null,
                        ),
                      ),
                      if (_isUploading)
                        const Positioned.fill(
                          child: Center(child: CircularProgressIndicator(color: primaryTeal)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _user['nama_lengkap'] ?? 'Nama Warga',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _user['email'] ?? '-',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : _pickAndUploadImage,
                      icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                      label: const Text('GANTI FOTO PROFIL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Column(
                children: [
                  _buildInfoRow(Icons.badge_outlined, 'Nomor NIK', 
                    _isNikVisible ? (_user['nik'] ?? '-') : _getMaskedNik(_user['nik'] ?? ''),
                    trailing: IconButton(
                      onPressed: () => setState(() => _isNikVisible = !_isNikVisible),
                      icon: Icon(
                        _isNikVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: const Color(0xFFCBD5E1),
                        size: 20,
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 70, color: Color(0xFFF1F5F9)),
                  _buildInfoRow(Icons.location_on_outlined, 'Alamat Lengkap', _user['alamat'] ?? '-'),
                  const Divider(height: 1, indent: 70, color: Color(0xFFF1F5F9)),
                  _buildInfoRow(Icons.phone_android_rounded, 'Nomor WhatsApp', _user['nomor_hp'] ?? '-'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSettingsTile(context, Icons.settings_outlined, 'Pengaturan', () {
               Navigator.push(context, MaterialPageRoute(builder: (c) => SettingsScreen(userName: _user['nama_lengkap'] ?? 'Warga', userNik: _user['nik'] ?? '-')));
            }),
            const SizedBox(height: 12),
            _buildSettingsTile(context, Icons.logout_rounded, 'Keluar Akun', () => _showLogoutDialog(), isDestructive: true),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: const Color(0xFF0F766E), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
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

  Widget _buildSettingsTile(BuildContext context, IconData icon, String title, VoidCallback onTap, {bool isDestructive = false, String? trailingText}) {
    const Color primaryTeal = Color(0xFF0F766E);
    const Color textDark = Color(0xFF1E293B);
    final Color iconColor = isDestructive ? Colors.red : primaryTeal;
    final Color textColor = isDestructive ? Colors.red : textDark;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: isDestructive ? Colors.red.withValues(alpha: 0.05) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
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
