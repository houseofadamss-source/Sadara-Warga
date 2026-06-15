import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, String> userData;
  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _namaController = TextEditingController();
  final _hpController = TextEditingController();
  final _alamatController = TextEditingController();
  
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _namaController.text = widget.userData['nama'] ?? '';
    _hpController.text = widget.userData['hp'] ?? '';
    _alamatController.text = widget.userData['alamat'] ?? '';
    _currentImageUrl = widget.userData['foto'];
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF0F766E);
    const Color textDark = Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Edit Profil', style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar Preview (Non-aktif)
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryTeal.withValues(alpha: 0.1), width: 4),
                      image: (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                          ? DecorationImage(image: NetworkImage(_currentImageUrl!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: (_currentImageUrl == null || _currentImageUrl!.isEmpty)
                      ? const Icon(Icons.person, size: 60, color: Colors.grey)
                      : null,
                  ),
                  Positioned(
                    right: 0, bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey.shade400, shape: BoxShape.circle),
                      child: const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 18),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            // Input Fields (Read-Only)
            _buildDisabledField('Nama Lengkap', _namaController, Icons.person_outline),
            _buildDisabledField('Nomor WhatsApp', _hpController, Icons.phone_android_rounded),
            _buildDisabledField('Alamat Lengkap', _alamatController, Icons.location_on_outlined, maxLines: 3),
            
            const SizedBox(height: 20),
            const Divider(height: 40, thickness: 1, color: Color(0xFFF1F5F9)),
            
            // Info Feature Coming Soon (Formal)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: primaryTeal, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Fitur pembaruan profil saat ini sedang dalam tahap pengembangan dan akan segera tersedia pada versi aplikasi mendatang.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        readOnly: true, // Non-aktifkan input
        maxLines: maxLines,
        style: const TextStyle(color: Color(0xFF94A3B8)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF64748B)),
          prefixIcon: Icon(icon, color: const Color(0xFFCBD5E1)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade100)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade100)),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
        ),
      ),
    );
  }
}
