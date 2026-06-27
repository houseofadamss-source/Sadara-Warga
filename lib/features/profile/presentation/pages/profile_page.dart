import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'settings_page.dart';
import 'faq_page.dart';
import 'about_page.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onBack;
  final VoidCallback onRefresh;

  const ProfilePage({
    super.key,
    required this.userData,
    required this.onBack,
    required this.onRefresh,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isUploading = false;
  final _picker = ImagePicker();

  Future<void> _updateProfilePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      final fileName = 'profile_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(image.path);

      await client.storage.from('avatars').upload(fileName, file);
      final imageUrl = client.storage.from('avatars').getPublicUrl(fileName);

      await client.from('users').update({'foto_profil': imageUrl}).eq('id', user.id);

      widget.onRefresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal upload: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF0F766E);
    const Color textDark = Color(0xFF1E293B);
    
    final String rawNik = widget.userData['nik'] ?? '-';
    final String maskedNik = rawNik.length > 4 
      ? '${rawNik.substring(0, 4)}**********' 
      : rawNik;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('PROFIL WARGA', style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 20),
          onPressed: widget.onBack,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryTeal.withOpacity(0.1), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: primaryTeal.withOpacity(0.05),
                          backgroundImage: widget.userData['foto_profil'] != null && widget.userData['foto_profil'].toString().isNotEmpty
                              ? NetworkImage(widget.userData['foto_profil'])
                              : null,
                          child: (widget.userData['foto_profil'] == null || widget.userData['foto_profil'].toString().isEmpty)
                              ? const Icon(Icons.person, size: 40, color: primaryTeal)
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isUploading ? null : _updateProfilePhoto,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: primaryTeal, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                            child: _isUploading
                                ? const SizedBox(height: 12, width: 12, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.userData['nama_lengkap'] ?? '-', 
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textDark, letterSpacing: -0.5)),
                        const SizedBox(height: 2),
                        Text(widget.userData['email'] ?? '-', 
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            'NIK: $maskedNik',
                            style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildSection(context, 'PENGATURAN & INFORMASI', [
              _buildMenuTile(Icons.settings_suggest_rounded, 'Pengaturan Aplikasi', 'Notifikasi, Keamanan, & Akun', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SettingsPage()))),
              _buildMenuTile(Icons.help_center_rounded, 'Pusat Bantuan (FAQ)', 'Pertanyaan umum seputar aplikasi', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const FaqPage()))),
              _buildMenuTile(Icons.info_rounded, 'Tentang Sadara Warga', 'Visi, misi, dan versi aplikasi', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AboutPage()))),
            ]),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 8))],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildMenuTile(IconData icon, String title, String sub, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: const Color(0xFF0F766E), size: 22)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFCBD5E1)),
    );
  }
}
