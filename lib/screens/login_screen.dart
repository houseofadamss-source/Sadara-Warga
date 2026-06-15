import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'register_screen.dart';

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
      _showProfessionalDialog(
        'Akses Dibekukan',
        'Demi keamanan data warga, akun Anda telah dibekukan sementara karena terlalu banyak percobaan masuk yang gagal.\n\nMohon hubungi Ketua RT atau RW setempat untuk memulihkan akses Anda.',
        Icons.lock_person,
        Colors.red,
      );
      return;
    }

    final inputID = _identifierController.text.trim();
    final password = _passwordController.text;

    if (inputID.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email/No. HP dan Kata Sandi wajib diisi!'))
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await Supabase.instance.client
          .from('users')
          .select()
          .or('nomor_hp.eq.$inputID,email.eq.$inputID')
          .maybeSingle();

      if (!mounted) return;

      if (user == null) {
        _showProfessionalDialog(
          'Akun Tidak Terdaftar',
          'Kami tidak menemukan Email atau Nomor Handphone tersebut di sistem kami.\n\nSilakan periksa kembali, atau daftar jika Anda adalah warga baru.',
          Icons.search_off,
          Colors.orange,
        );
      } else {
        if (user['password_hash'] != password) {
          _failedAttempts++;
          if (_failedAttempts >= 3) {
            setState(() => _isBlocked = true);
            _showProfessionalDialog(
              'Akses Dibekukan',
              'Demi keamanan, akun Anda dibekukan sementara karena salah memasukkan kata sandi sebanyak 3 kali.\n\nMohon hubungi Ketua RT/RW setempat untuk memulihkan akses Anda.',
              Icons.gpp_bad,
              Colors.red,
            );
          } else {
            int sisa = 3 - _failedAttempts;
            _showProfessionalDialog(
              'Kata Sandi Keliru',
              'Kata sandi yang Anda masukkan salah. Sisa percobaan: $sisa kali lagi.',
              Icons.warning_amber_rounded,
              Colors.orange,
            );
          }
        } else {
          _failedAttempts = 0;
          final statusAkun = user['status_akun'];

          if (statusAkun == 'pending') {
            _showProfessionalDialog(
              'Proses Verifikasi',
              'Status pendaftaran sedang menunggu verifikasi dari Ketua RT/RW setempat',
              Icons.hourglass_bottom,
              Colors.blue,
            );
          } else if (statusAkun == 'rejected') {
            _showProfessionalDialog(
              'Pendaftaran Ditolak',
              'Status pendaftaran anda di tolak, hubungi ketua RT atau RW setempat, untuk melakukan konfirmasi',
              Icons.cancel,
              Colors.red,
            );
          } else if (statusAkun == 'approved') {
            // Simpan sesi login
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('userName', user['nama_lengkap'] ?? 'Warga');
            await prefs.setString('userNik', user['nik'] ?? '');
            await prefs.setString('userRole', user['role'] ?? 'warga');

            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          } else {
            _showProfessionalDialog(
              'Status Tidak Dikenal',
              'Akun Anda memiliki status yang tidak valid. Mohon hubungi administrator.',
              Icons.error_outline,
              Colors.grey,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: ${e.toString()}'))
        );
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryTeal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.location_city_rounded, size: 40, color: primaryTeal),
            ),
            const SizedBox(height: 24),
            const Text(
              'Selamat Datang!',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Silakan masuk dengan akun warga Anda yang telah divalidasi RT.',
              style: TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 40),

            _buildModernField(
              controller: _identifierController,
              focusNode: _idFocus,
              label: 'Email atau Nomor Handphone',
              icon: Icons.person_outline_rounded,
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
            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  _showProfessionalDialog(
                    'Fitur Dalam Pengembangan',
                    'Sistem pemulihan kata sandi otomatis sedang dalam tahap penyempurnaan.\n\nMohon hubungi Ketua RT atau RW untuk bantuan reset kata sandi.',
                    Icons.support_agent_rounded,
                    Colors.blue,
                  );
                },
                child: const Text(
                  'Lupa Sandi?',
                  style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold),
                ),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: _isBlocked ? 0 : 8,
                  shadowColor: primaryTeal.withValues(alpha: 0.3),
                ),
                onPressed: (_isLoading || _isBlocked) ? null : _masukAplikasi,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'MASUK SEKARANG',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Belum punya akun?', style: TextStyle(color: Color(0xFF64748B))),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  ),
                  child: const Text(
                    'Daftar Warga',
                    style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold),
                  ),
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
