import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sadarawarga/injection_container.dart';
import 'package:sadarawarga/services/device_service.dart';
import 'package:sadarawarga/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sadarawarga/features/auth/presentation/bloc/auth_event.dart';
import 'package:sadarawarga/features/auth/presentation/bloc/auth_state.dart' as bloc_state;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nikController = TextEditingController();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _hpController = TextEditingController();
  final _alamatController = TextEditingController();
  final _passwordController = TextEditingController();

  final _nikFocus = FocusNode();
  final _namaFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _hpFocus = FocusNode();
  final _alamatFocus = FocusNode();
  final _passFocus = FocusNode();

  bool _obscureText = true;
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasSpecialChar = false;

  File? _fotoKk;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nikFocus.addListener(() => setState(() {}));
    _namaFocus.addListener(() => setState(() {}));
    _emailFocus.addListener(() => setState(() {}));
    _hpFocus.addListener(() => setState(() {}));
    _alamatFocus.addListener(() => setState(() {}));
    _passFocus.addListener(() => setState(() {}));
  }

  void _validatePassword(String value) {
    setState(() {
      _hasMinLength = value.length >= 8;
      _hasUppercase = value.contains(RegExp(r'[A-Z]'));
      _hasLowercase = value.contains(RegExp(r'[a-z]'));
      _hasSpecialChar = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  Future<void> _pilihFotoKK() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (image != null) {
        setState(() => _fotoKk = File(image.path));
      }
    } catch (e) {
      _showProfessionalDialog(context, 'Akses Galeri Ditolak', 'Mohon izinkan aplikasi untuk mengakses galeri Anda.', Icons.photo_library_outlined, Colors.red);
    }
  }

  void _onRegisterPressed(BuildContext context) async {
    final nik = _nikController.text.trim();
    final nama = _namaController.text.trim();
    final email = _emailController.text.trim();
    final hp = _hpController.text.trim();
    final alamat = _alamatController.text.trim();
    final password = _passwordController.text;

    if (nik.isEmpty || nama.isEmpty || email.isEmpty || hp.isEmpty || password.isEmpty || alamat.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon lengkapi semua data pendaftaran.')));
      return;
    }

    if (nik.length != 16) {
      _showProfessionalDialog(context, 'NIK Tidak Valid', 'NIK wajib terdiri dari 16 angka sesuai KTP.', Icons.badge_outlined, Colors.orange);
      return;
    }

    if (!_hasMinLength || !_hasUppercase || !_hasLowercase || !_hasSpecialChar) {
      _showProfessionalDialog(context, 'Sandi Kurang Kuat', 'Pastikan kata sandi memenuhi kriteria keamanan.', Icons.lock_outline, Colors.orange);
      return;
    }

    if (_fotoKk == null) {
      _showProfessionalDialog(context, 'Foto KK Dibutuhkan', 'Mohon unggah foto Kartu Keluarga untuk verifikasi data.', Icons.camera_alt_outlined, Colors.orange);
      return;
    }

    final client = Supabase.instance.client;
    final existingNik = await client.from('users').select().eq('nik', nik).maybeSingle();
    if (existingNik != null) {
      if (context.mounted) _showProfessionalDialog(context, 'NIK Terdaftar', 'NIK ini sudah digunakan. Silakan hubungi RT/RW.', Icons.badge, Colors.red);
      return;
    }

    if (context.mounted) {
      final tempId = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'kk_pending_$tempId.jpg';
      final storagePath = 'foto_kk/$fileName';
      
      try {
        await client.storage.from('berkas_warga').upload(storagePath, _fotoKk!);
        final publicFotoUrl = client.storage.from('berkas_warga').getPublicUrl(storagePath);
        final deviceId = await DeviceService().getUniqueId();

        if (context.mounted) {
          context.read<AuthBloc>().add(RegisterRequested(
            nik: nik,
            nama: nama,
            email: email,
            hp: hp,
            alamat: alamat,
            password: password,
            fotoKkUrl: publicFotoUrl,
            deviceId: deviceId,
          ));
        }
      } catch (e) {
        if (context.mounted) _showProfessionalDialog(context, 'Gagal Unggah', 'Gagal mengunggah foto KK: $e', Icons.error_outline, Colors.red);
      }
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
              ),
              const SizedBox(height: 24),
              const Text('Berhasil Terdaftar!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 12),
              const Text(
                'Akun Anda berhasil dibuat dan sedang menunggu verifikasi dari Pengurus RT. Mohon tunggu kabar selanjutnya.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Back to Welcome/Login
                  },
                  child: const Text('SIAP, MENGERTI', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showProfessionalDialog(BuildContext context, String title, String message, IconData icon, Color iconColor) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ],
          ),
          content: Text(message, style: const TextStyle(height: 1.5, fontSize: 14, color: Color(0xFF475569))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('MENGERTI', style: TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF0F766E);

    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: BlocListener<AuthBloc, bloc_state.AuthState>(
        listener: (context, state) {
          if (state is bloc_state.RegisterSuccess) {
            _showSuccessDialog(context);
          } else if (state is bloc_state.AuthFailureState) {
            _showProfessionalDialog(context, 'Gagal Mendaftar', state.message, Icons.error_outline, Colors.red);
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: const Text('Daftar Warga Baru', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 18)),
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 20), onPressed: () => Navigator.pop(context)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lengkapi Data Diri', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 8),
                const Text('Pastikan data yang Anda masukkan sesuai dengan KTP & KK asli.', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                const SizedBox(height: 32),
                _buildSectionTitle('IDENTITAS UTAMA'),
                _buildModernField(controller: _nikController, focusNode: _nikFocus, label: 'Nomor NIK', hint: '16 Digit sesuai KTP', icon: Icons.badge_outlined, keyboardType: TextInputType.number),
                _buildModernField(controller: _namaController, focusNode: _namaFocus, label: 'Nama Lengkap', hint: 'Sesuai KTP', icon: Icons.person_outline),
                _buildSectionTitle('KONTAK & ALAMAT'),
                _buildModernField(controller: _emailController, focusNode: _emailFocus, label: 'Email Aktif', hint: 'contoh@mail.com', icon: Icons.alternate_email_rounded, keyboardType: TextInputType.emailAddress),
                _buildModernField(controller: _hpController, focusNode: _hpFocus, label: 'Nomor WhatsApp', hint: '0812xxxxxxxx', icon: Icons.phone_android_rounded, keyboardType: TextInputType.phone),
                _buildModernField(controller: _alamatController, focusNode: _alamatFocus, label: 'Alamat Tinggal', hint: 'Jl, No, RT/RW', icon: Icons.map_outlined, maxLines: 2),
                _buildSectionTitle('DOKUMEN PENDUKUNG'),
                InkWell(
                  onTap: _pilihFotoKK,
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _fotoKk != null ? Colors.green.withValues(alpha: 0.05) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _fotoKk != null ? Colors.green : Colors.blue.withValues(alpha: 0.2), width: 2, style: BorderStyle.solid),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        Icon(_fotoKk != null ? Icons.check_circle_rounded : Icons.cloud_upload_outlined, color: _fotoKk != null ? Colors.green : primaryTeal, size: 40),
                        const SizedBox(height: 12),
                        Text(_fotoKk != null ? 'Foto KK Siap Dikirim' : 'Upload Foto Kartu Keluarga', style: TextStyle(color: _fotoKk != null ? Colors.green.shade700 : const Color(0xFF1E293B), fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Format JPG/PNG, Max 2MB', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _buildSectionTitle('KEAMANAN AKUN'),
                _buildModernField(
                  controller: _passwordController,
                  focusNode: _passFocus,
                  label: 'Buat Kata Sandi',
                  icon: Icons.lock_open_rounded,
                  obscureText: _obscureText,
                  onChanged: _validatePassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF94A3B8)),
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  ),
                ),
                _buildPasswordCriteria(),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final state = context.watch<AuthBloc>().state;
                    final isLoading = state is bloc_state.AuthLoading;

                    return SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTeal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 8,
                          shadowColor: primaryTeal.withValues(alpha: 0.3),
                        ),
                        onPressed: isLoading ? null : () => _onRegisterPressed(context),
                        child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('DAFTAR SEKARANG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1)),
                      ),
                    );
                  }
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    int maxLines = 1,
    Function(String)? onChanged,
    String? hint,
  }) {
    const Color primaryTeal = Color(0xFF0F766E);
    bool isFocused = focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isFocused ? primaryTeal.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: maxLines,
        onChanged: onChanged,
        cursorColor: primaryTeal,
        cursorWidth: 2.5,
        cursorRadius: const Radius.circular(2),
        style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5), fontSize: 13),
          labelStyle: TextStyle(
            color: isFocused ? primaryTeal : const Color(0xFF64748B),
            fontSize: 14,
            fontWeight: isFocused ? FontWeight.bold : FontWeight.normal,
          ),
          prefixIcon: Icon(icon, color: isFocused ? primaryTeal : const Color(0xFF94A3B8), size: 22),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1.2)),
    );
  }

  Widget _buildPasswordCriteria() {
    if (_passwordController.text.isEmpty && !_passFocus.hasFocus) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 24, top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildCheckRow('Minimal 8 Karakter', _hasMinLength),
          _buildCheckRow('Huruf Besar & Kecil', _hasUppercase && _hasLowercase),
          _buildCheckRow('Karakter Spesial (!@#)', _hasSpecialChar),
        ],
      ),
    );
  }

  Widget _buildCheckRow(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(isValid ? Icons.check_circle : Icons.circle_outlined, size: 16, color: isValid ? Colors.green : Colors.grey),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 12, color: isValid ? Colors.green.shade700 : const Color(0xFF64748B), fontWeight: isValid ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nikController.dispose();
    _namaController.dispose();
    _emailController.dispose();
    _hpController.dispose();
    _alamatController.dispose();
    _passwordController.dispose();
    _nikFocus.dispose();
    _namaFocus.dispose();
    _emailFocus.dispose();
    _hpFocus.dispose();
    _alamatFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }
}
