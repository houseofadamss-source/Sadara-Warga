import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/citizen_entity.dart';
import '../../domain/repositories/citizen_repository.dart';
import '../bloc/citizen_bloc.dart';
import '../bloc/citizen_event.dart';
import '../bloc/citizen_state.dart';

class AdminVerifikasiPage extends StatelessWidget {
  const AdminVerifikasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CitizenBloc>(),
      child: const AdminVerifikasiView(),
    );
  }
}

class AdminVerifikasiView extends StatefulWidget {
  const AdminVerifikasiView({super.key});

  @override
  State<AdminVerifikasiView> createState() => _AdminVerifikasiViewState();
}

class _AdminVerifikasiViewState extends State<AdminVerifikasiView> with SingleTickerProviderStateMixin {
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
      body: BlocListener<CitizenBloc, CitizenState>(
        listener: (context, state) {
          if (state is CitizenActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: primaryTeal));
          } else if (state is CitizenFailure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildUserList('pending', primaryTeal, textDark),
            _buildUserList('approved', primaryTeal, textDark),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(String status, Color primaryTeal, Color textDark) {
    return StreamBuilder<List<CitizenEntity>>(
      stream: sl<CitizenRepository>().watchCitizens(status),
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
                          : 'Berikut adalah daftar warga yang telah memiliki akses penuh. Anda juga bisa mengatur peran (Admin) di sini.',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xCC64748B),
                        height: 1.5,
                      ),
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
                      final bool isAdmin = user.role == 'super_admin';

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
                                backgroundImage: (user.fotoProfil != null && user.fotoProfil!.isNotEmpty)
                                    ? NetworkImage(user.fotoProfil!)
                                    : null,
                                child: (user.fotoProfil == null || user.fotoProfil!.isEmpty)
                                    ? Icon(Icons.person, color: primaryTeal)
                                    : null,
                              ),
                              title: Row(
                                children: [
                                  Expanded(child: Text(user.namaLengkap, style: TextStyle(fontWeight: FontWeight.bold, color: textDark))),
                                  if (isAdmin)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                      child: const Text('ADMIN', style: TextStyle(color: Colors.indigo, fontSize: 8, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                              subtitle: Text('NIK: ${user.nik}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              trailing: status == 'approved' ? const Icon(Icons.check_circle, color: Colors.green, size: 20) : null,
                            ),
                            if (user.fotoKk != null && user.fotoKk!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(user.fotoKk!, height: 180, width: double.infinity, fit: BoxFit.cover),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: status == 'pending' 
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => context.read<CitizenBloc>().add(UpdateCitizenStatusRequested(user.id, 'approved')),
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
                                          onPressed: () => context.read<CitizenBloc>().add(UpdateCitizenStatusRequested(user.id, 'rejected')),
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
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () => context.read<CitizenBloc>().add(ToggleCitizenRoleRequested(user.id, user.role)),
                                              icon: Icon(isAdmin ? Icons.person_remove_rounded : Icons.admin_panel_settings_rounded, size: 18),
                                              label: Text(isAdmin ? 'CABUT ADMIN' : 'JADIKAN ADMIN', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: isAdmin ? Colors.orange.shade50 : Colors.indigo.shade50,
                                                foregroundColor: isAdmin ? Colors.orange.shade800 : Colors.indigo.shade800,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () => context.read<CitizenBloc>().add(ResetCitizenDeviceRequested(user.id)),
                                              icon: const Icon(Icons.phonelink_erase_rounded, size: 18),
                                              label: const Text('RESET HP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue.shade50,
                                                foregroundColor: Colors.blue.shade700,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: () => context.read<CitizenBloc>().add(UpdateCitizenStatusRequested(user.id, 'pending')),
                                          icon: const Icon(Icons.undo_rounded, size: 18),
                                          label: const Text('BATALKAN VERIFIKASI', style: TextStyle(fontSize: 11)),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.grey,
                                            side: BorderSide(color: Colors.grey.shade300),
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
