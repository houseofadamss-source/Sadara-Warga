import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sadarawarga/injection_container.dart';
import 'package:sadarawarga/features/home/presentation/pages/home_page.dart';
import 'package:sadarawarga/services/device_service.dart';
import 'package:sadarawarga/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sadarawarga/features/auth/presentation/bloc/auth_event.dart';
import 'package:sadarawarga/features/auth/presentation/bloc/auth_state.dart' as bloc_state;
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _idFocus = FocusNode();
  final _passFocus = FocusNode();

  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _idFocus.addListener(() => setState(() {}));
    _passFocus.addListener(() => setState(() {}));
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

  void _onLoginPressed(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email dan Kata Sandi wajib diisi!')));
      return;
    }

    final deviceId = await DeviceService().getUniqueId();
    
    if (context.mounted) {
      context.read<AuthBloc>().add(LoginRequested(
        email: email,
        password: password,
        deviceId: deviceId,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF0F766E);
    const Color textDark = Color(0xFF1E293B);

    return BlocProvider(
      create: (_) => sl<AuthBloc>(),
      child: BlocListener<AuthBloc, bloc_state.AuthState>(
        listener: (context, state) async {
          if (state is bloc_state.AuthSuccess) {
            final user = state.user;
            
            if (user.statusAkun == 'approved') {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', true);
              await prefs.setString('userName', user.namaLengkap);
              await prefs.setString('userNik', user.nik);
              await prefs.setString('userRole', user.role);

              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                  (route) => false,
                );
              }
            } else if (user.statusAkun == 'pending') {
              _showProfessionalDialog(context, 'Proses Verifikasi', 'Akun Anda sedang menunggu persetujuan dari Pengurus RT.', Icons.hourglass_bottom, Colors.blue);
            } else if (user.statusAkun == 'rejected') {
              _showProfessionalDialog(context, 'Pendaftaran Ditolak', 'Status pendaftaran Anda ditolak. Silakan hubungi RT/RW.', Icons.cancel, Colors.red);
            }
          } else if (state is bloc_state.AuthFailureState) {
            String message = state.message;
            if (message.contains('invalid login credentials')) {
              message = 'Email atau Kata Sandi salah. Pastikan penulisan sudah benar.';
            }
            _showProfessionalDialog(context, 'Gagal Masuk', message, Icons.warning_amber_rounded, Colors.orange);
          }
        },
        child: Scaffold(
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
                const Text('Silakan masuk dengan akun warga Anda yang telah didaftarkan.', style: TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.6)),
                const SizedBox(height: 40),

                _buildModernField(
                  controller: _emailController,
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
                          shadowColor: primaryTeal.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 8,
                        ),
                        onPressed: isLoading ? null : () => _onLoginPressed(context),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('MASUK SEKARANG', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                      ),
                    );
                  }
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Warga baru?', style: TextStyle(color: Color(0xFF64748B))),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage())),
                      child: const Text('Mulai Daftar', style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold)),
                    ),
                  ],
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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _idFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }
}
