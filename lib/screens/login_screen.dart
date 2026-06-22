import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import '../services/device_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _idFocus = FocusNode();
  final _passFocus = FocusNode();

  bool _obscureText = true;
  bool _isLoading = false;

  int _failedAttempts = 0;
  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    _idFocus.addListener(() => setState(() {}));
    _passFocus.addListener(() => setState(() {}));
  }

  void _showProfessionalDialog(String title, String message, IconData icon, Color iconColor) {
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

  Future<void> _masukAplikasi() async {
    if (_isBlocked) {
      _showProfessionalDialog('Akses Dibekukan', 'Akun Anda dibekukan sementara karena terlalu banyak percobaan gagal.', Icons.lock_person, Colors.red);
      return;
    }

    final emailInput = _identifierController.text.trim();
    final password = _passwordController.text;

    if (emailInput.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email dan Kata Sandi wajib diisi!')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final client = Supabase.instance.client;

      // 1. Login via Supabase Auth
      final AuthResponse res = await client.auth.signInWithPassword(
        email: emailInput,
        password: password,
      );

      final String? userId = res.user?.id;
      if (userId == null) throw 'Gagal mendapatkan data sesi.';

      // 2. Ambil data tambahan dari tabel public.users
      final userMetadata = await client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (!mounted) return;

      if (userMetadata == null) {
        await client.auth.signOut();
        _showProfessionalDialog('Profil Tidak Ditemukan', 'Email Anda terdaftar di sistem Auth, tapi data warga Anda di tabel Users kosong. Hubungi Pengurus.', Icons.error_outline, Colors.orange);
        return;
      }

      final statusAkun = userMetadata['status_akun'].toString().toLowerCase();

      if (statusAkun == 'pending') {
        await client.auth.signOut();
        _showProfessionalDialog('Proses Verifikasi', 'Akun Anda sedang menunggu persetujuan dari Pengurus RT.', Icons.hourglass_bottom, Colors.blue);
      } else if (statusAkun == 'rejected') {
        await client.auth.signOut();
        _showProfessionalDialog('Pendaftaran Ditolak', 'Status pendaftaran Anda ditolak. Silakan hubungi RT/RW.', Icons.cancel, Colors.red);
      } else if (statusAkun == 'approved') {
        // --- LOGIC GEMBOK HP (ONE DEVICE POLICY) ---
        final currentDeviceId = await DeviceService().getUniqueId();
        final registeredDeviceId = userMetadata['device_id'];

        if (registeredDeviceId == null) {
          // Kasus Warga Lama (Belum ada ID HP), kita daftarkan HP ini sekarang
          await client.from('users').update({'device_id': currentDeviceId}).eq('id', userId);
        } else if (registeredDeviceId != currentDeviceId) {
          // HP Berbeda! Tendang keluar
          await client.auth.signOut();
          _showProfessionalDialog(
            'Perangkat Tidak Dikenali', 
            'Akun Anda terikat pada perangkat lain. Jika Anda mengganti HP, silakan hubungi Pak RT untuk reset perangkat.', 
            Icons.phonelink_lock_rounded, 
            Colors.orange
          );
          setState(() => _isLoading = false);
          return;
        }
        // --------------------------------------------

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userName', userMetadata['nama_lengkap'] ?? 'Warga');
        await prefs.setString('userNik', userMetadata['nik'] ?? '');
        await prefs.setString('userRole', userMetadata['role'] ?? 'warga');

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }

    } catch (e) {
      String errorMessage = 'Email atau Kata Sandi Anda salah.';
      
      // Deteksi error spesifik dari Supabase
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('email not confirmed')) {
        errorMessage = 'Email Anda belum dikonfirmasi. Mohon cek inbox/spam email Anda dan klik link konfirmasi.';
      } else if (errorStr.contains('invalid login credentials')) {
        errorMessage = 'Email atau Kata Sandi salah. Pastikan penulisan sudah benar.';
      } else {
        errorMessage = 'Gagal masuk: ${e.toString()}';
      }

      _failedAttempts++;
      if (_failedAttempts >= 5) { // Gue longgarin dikit biar gak gampang keblokir pas testing
        setState(() => _isBlocked = true);
        _showProfessionalDialog('Akses Dibekukan', 'Terlalu banyak percobaan gagal. Silakan hubungi Admin Wilayah.', Icons.gpp_bad, Colors.red);
      } else {
        _showProfessionalDialog('Masuk Gagal', errorMessage, Icons.warning_amber_rounded, Colors.orange);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildModernField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    const Color primaryTeal = Color(0xFF0F766E);
    bool isFocused = focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
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
        cursorColor: primaryTeal,
        cursorWidth: 2.5,
        cursorRadius: const Radius.circular(2),
        style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isFocused ? primaryTeal : const Color(0xFF64748B),
            fontSize: 14,
            fontWeight: isFocused ? FontWeight.bold : FontWeight.normal,
          ),
          prefixIcon: Icon(icon, color: isFocused ? primaryTeal : const Color(0xFF94A3B8), size: 22),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF0F766E);
    const Color textDark = Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: primaryTeal.withValues(alpha: 0.1), width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/Logo.png',
                  height: 60,
                  width: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.location_city_rounded,
                    size: 40,
                    color: primaryTeal,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Selamat Datang!', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 8),
            const Text('Silakan masuk dengan akun warga Anda yang telah didaftarkan.', style: TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.5)),
            const SizedBox(height: 40),

            _buildModernField(
              controller: _identifierController,
              focusNode: _idFocus,
              label: 'Email Terdaftar',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),

            _buildModernField(
              controller: _passwordController,
              focusNode: _passFocus,
              label: 'Kata Sandi',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscureText,
              suffixIcon: IconButton(
                icon: Icon(_obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF94A3B8)),
                onPressed: () => setState(() => _obscureText = !_obscureText),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isBlocked ? Colors.grey : primaryTeal,
                  foregroundColor: Colors.white,
                  shadowColor: primaryTeal.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: _isBlocked ? 0 : 8,
                ),
                onPressed: (_isLoading || _isBlocked) ? null : _masukAplikasi,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('MASUK SEKARANG', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Warga baru?', style: TextStyle(color: Color(0xFF64748B))),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                  child: const Text('Mulai Daftar', style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _idFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }
}
