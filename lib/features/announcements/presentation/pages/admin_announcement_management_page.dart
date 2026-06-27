import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/announcement_entity.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../bloc/announcement_bloc.dart';
import '../bloc/announcement_event.dart';
import '../bloc/announcement_state.dart';

import 'add_announcement_page.dart';

class AdminAnnouncementManagementPage extends StatelessWidget {
  const AdminAnnouncementManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AnnouncementBloc>(),
      child: const AdminAnnouncementManagementView(),
    );
  }
}

class AdminAnnouncementManagementView extends StatefulWidget {
  const AdminAnnouncementManagementView({super.key});

  @override
  State<AdminAnnouncementManagementView> createState() => _AdminAnnouncementManagementViewState();
}

class _AdminAnnouncementManagementViewState extends State<AdminAnnouncementManagementView> {
  String _userRole = 'warga';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('userRole') ?? 'warga';
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color textDark = Color(0xFF1E293B);
    const Color primaryTeal = Color(0xFF0F766E);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('KELOLA PENGUMUMAN',
            style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 20),
            onPressed: () => Navigator.pop(context)),
      ),
      body: BlocListener<AnnouncementBloc, AnnouncementState>(
        listener: (context, state) {
          if (state is AnnouncementActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: primaryTeal));
          } else if (state is AnnouncementFailure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        child: StreamBuilder<List<AnnouncementEntity>>(
          stream: sl<AnnouncementRepository>().getAnnouncements('all'),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: primaryTeal));
            }

            final items = snapshot.data ?? [];

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ARSIP INFORMASI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
                        const SizedBox(height: 8),
                        Text(
                          _userRole == 'super_admin'
                              ? 'Klik ikon bintang untuk menyematkan ke Banner Beranda. Geser ke kiri untuk menghapus.'
                              : 'Geser ke kiri pada kartu pengumuman untuk menghapusnya secara permanen.',
                          style: TextStyle(fontSize: 13, color: const Color(0xFF64748B).withValues(alpha: 0.8), height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
                if (items.isEmpty)
                  const SliverFillRemaining(child: Center(child: Text('Belum ada pengumuman.')))
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = items[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Dismissible(
                              key: Key(item.id),
                              direction: DismissDirection.endToStart,
                              onDismissed: (dir) =>
                                  context.read<AnnouncementBloc>().add(DeleteAnnouncementRequested(item.id)),
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(24)),
                                child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 30),
                                  Text('HAPUS',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10))
                                ]),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: item.isFeatured ? Border.all(color: Colors.amber.shade300, width: 2) : null,
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Stack(
                                      children: [
                                        if (item.fileUrl != null && item.fileUrl!.isNotEmpty)
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(14),
                                            child: Image.network(item.fileUrl!, height: 70, width: 70, fit: BoxFit.cover),
                                          )
                                        else
                                          Container(
                                            height: 70,
                                            width: 70,
                                            decoration: BoxDecoration(
                                                color: (item.tipe == 'kabar' ? Colors.orange : primaryTeal)
                                                    .withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(14)),
                                            child: Icon(item.tipe == 'kabar' ? Icons.bolt_rounded : Icons.newspaper_rounded,
                                                color: item.tipe == 'kabar' ? Colors.orange : primaryTeal, size: 30),
                                          ),
                                        if (item.isFeatured)
                                          const Positioned(
                                            top: -2,
                                            right: -2,
                                            child: Icon(Icons.stars_rounded, color: Colors.amber, size: 24),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                    color: (item.tipe == 'kabar' ? Colors.orange : primaryTeal)
                                                        .withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(6)),
                                                child: Text(item.tipe == 'kabar' ? 'KABAR' : 'BERITA',
                                                    style: TextStyle(
                                                        color: item.tipe == 'kabar' ? Colors.orange : primaryTeal,
                                                        fontSize: 8,
                                                        fontWeight: FontWeight.bold,
                                                        letterSpacing: 0.5)),
                                              ),
                                              const Spacer(),
                                              IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                icon: Icon(Icons.edit_note_rounded, color: Colors.blue.shade300, size: 22),
                                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => AddAnnouncementPage(announcement: item))),
                                              ),
                                              const SizedBox(width: 8),
                                              if (_userRole == 'super_admin')
                                                IconButton(
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  icon: Icon(
                                                      item.isFeatured ? Icons.star_rounded : Icons.star_outline_rounded,
                                                      color: item.isFeatured ? Colors.amber : Colors.grey.shade400,
                                                      size: 22),
                                                  onPressed: () => context
                                                      .read<AnnouncementBloc>()
                                                      .add(ToggleFeaturedRequested(item.id, item.isFeatured)),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(item.judul,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: textDark,
                                                  height: 1.2),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.tipe == 'kabar' ? item.konten : (item.subJudul ?? ''),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: items.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AddAnnouncementPage())),
        backgroundColor: primaryTeal,
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
        label: const Text('BUAT PENGUMUMAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
