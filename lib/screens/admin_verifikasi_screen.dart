import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminVerifikasiScreen extends StatefulWidget {
  const AdminVerifikasiScreen({super.key});

  @override
  State<AdminVerifikasiScreen> createState() => _AdminVerifikasiScreenState();
}

class _AdminVerifikasiScreenState extends State<AdminVerifikasiScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updateUserStatus(BuildContext context, String userId, String status) async {
    try {
      await Supabase.instance.client.from('users').update({'status_akun': status}).eq('id', userId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(status == 'approved' ? 'Warga berhasil disetujui!' : 'Pendaftaran ditolak.'),
          backgroundColor: status == 'approved' ? const Color(0xFF0F766E) : Colors.red,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  Future<void> _resetDeviceId(BuildContext context, String userId) async {
    try {
      await Supabase.instance.client.from('users').update({'device_id': null}).eq('id', userId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gembok HP berhasil di-reset! Warga bisa login di HP baru.'),
          backgroundColor: Colors.blue,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal reset: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF0F766E);
    const Color textDark = Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('MANAJEMEN WARGA', style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 20), onPressed: () => Navigator.pop(context)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryTeal,
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: primaryTeal,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(text: 'BELUM VERIFIKASI'),
            Tab(text: 'SUDAH VERIFIKASI'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserList('pending', primaryTeal, textDark),
          _buildUserList('approved', primaryTeal, textDark),
        ],
      ),
    );
  }

  Widget _buildUserList(String status, Color primaryTeal, Color textDark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client.from('users').stream(primaryKey: ['id']).eq('status_akun', status).order('nama_lengkap'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: primaryTeal));
        
        final users = snapshot.data ?? [];

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status == 'pending' ? 'PERMINTAAN VALIDASI' : 'DATA WARGA TERDAFTAR',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      status == 'pending'
                          ? 'Periksa kesesuaian Nama dan NIK dengan Foto KK yang diunggah warga sebelum menyetujui akses.'
                          : 'Berikut adalah daftar warga yang telah memiliki akses penuh ke aplikasi Sadara Warga.',
                      style: TextStyle(fontSize: 13, color: const Color(0xFF64748B).withValues(alpha: 0.8), height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            if (users.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(status == 'pending' ? Icons.verified_user_outlined : Icons.people_outline_rounded, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        status == 'pending' ? 'Tidak ada permintaan verifikasi' : 'Belum ada warga yang terverifikasi',
                        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final user = users[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFF1F5F9),
                                backgroundImage: (user['foto_profil'] != null && user['foto_profil'].toString().isNotEmpty)
                                    ? NetworkImage(user['foto_profil'])
                                    : null,
                                child: (user['foto_profil'] == null || user['foto_profil'].toString().isEmpty)
                                    ? Icon(Icons.person, color: primaryTeal)
                                    : null,
                              ),
                              title: Text(user['nama_lengkap'] ?? '-', style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
                              subtitle: Text('NIK: ${user['nik']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              trailing: status == 'approved' ? const Icon(Icons.check_circle, color: Colors.green, size: 20) : null,
                            ),
                            if (user['foto_kk'] != null && user['foto_kk'].toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(user['foto_kk'], height: 180, width: double.infinity, fit: BoxFit.cover),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: status == 'pending' 
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _updateUserStatus(context, user['id'], 'approved'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryTeal,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          ),
                                          child: const Text('SETUJUI', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _updateUserStatus(context, user['id'], 'rejected'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: const BorderSide(color: Colors.red),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          ),
                                          child: const Text('TOLAK', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () => _resetDeviceId(context, user['id']),
                                          icon: const Icon(Icons.phonelink_erase_rounded, size: 18),
                                          label: const Text('RESET GEMBOK HP'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue.shade50,
                                            foregroundColor: Colors.blue.shade700,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: () => _updateUserStatus(context, user['id'], 'pending'),
                                          icon: const Icon(Icons.undo_rounded, size: 18),
                                          label: const Text('BATALKAN VERIFIKASI'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.orange,
                                            side: const BorderSide(color: Colors.orange),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: users.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        );
      },
    );
  }
}
