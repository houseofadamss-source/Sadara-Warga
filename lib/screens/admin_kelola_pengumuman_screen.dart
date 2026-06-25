import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminKelolaPengumumanScreen extends StatefulWidget {
  const AdminKelolaPengumumanScreen({super.key});

  @override
  State<AdminKelolaPengumumanScreen> createState() => _AdminKelolaPengumumanScreenState();
}

class _AdminKelolaPengumumanScreenState extends State<AdminKelolaPengumumanScreen> {
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;
  String _userRole = 'warga';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _fetchAnnouncements();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('userRole') ?? 'warga';
    });
  }

  Future<void> _fetchAnnouncements() async {
    try {
      final data = await Supabase.instance.client
          .from('announcements')
          .select()
          .order('created_at', ascending: false);
      
      if (mounted) {
        setState(() {
          _announcements = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFeatured(String id, bool currentStatus) async {
    if (_userRole != 'super_admin') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Akses Ditolak: Hanya Super Admin yang bisa melakukan ini.')));
      return;
    }

    try {
      await Supabase.instance.client
          .from('announcements')
          .update({'is_featured': !currentStatus})
          .eq('id', id);
      
      _fetchAnnouncements(); // Refresh data
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!currentStatus ? 'Berhasil disematkan ke Banner!' : 'Berhasil dilepas dari Banner.'),
            backgroundColor: !currentStatus ? Colors.indigo : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _deleteAnnouncement(String id) async {
    final backup = List<Map<String, dynamic>>.from(_announcements);
    setState(() {
      _announcements.removeWhere((item) => item['id'].toString() == id);
    });

    try {
      await Supabase.instance.client
          .from('announcements')
          .delete()
          .eq('id', id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengumuman berhasil dihapus'), backgroundColor: Color(0xFF0F766E)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _announcements = backup);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: Colors.red));
      }
    }
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
        title: const Text('KELOLA PENGUMUMAN', style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: primaryTeal))
        : CustomScrollView(
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
              if (_announcements.isEmpty)
                const SliverFillRemaining(child: Center(child: Text('Belum ada pengumuman.')))
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = _announcements[index];
                        final String id = item['id'].toString();
                        final String tipe = item['tipe'] ?? 'kabar';
                        final bool isFeatured = item['is_featured'] ?? false;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Dismissible(
                            key: Key(id),
                            direction: DismissDirection.endToStart,
                            onDismissed: (dir) => _deleteAnnouncement(id),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(24)),
                              child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 30), Text('HAPUS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10))]),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: isFeatured ? Border.all(color: Colors.amber.shade300, width: 2) : null,
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    children: [
                                      if (item['file_url'] != null && item['file_url'].toString().isNotEmpty)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(14),
                                          child: Image.network(item['file_url'], height: 70, width: 70, fit: BoxFit.cover),
                                        )
                                      else
                                        Container(
                                          height: 70, width: 70,
                                          decoration: BoxDecoration(color: (tipe == 'kabar' ? Colors.orange : primaryTeal).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                                          child: Icon(tipe == 'kabar' ? Icons.bolt_rounded : Icons.newspaper_rounded, color: tipe == 'kabar' ? Colors.orange : primaryTeal, size: 30),
                                        ),
                                      if (isFeatured)
                                        const Positioned(
                                          top: -2, right: -2,
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
                                              decoration: BoxDecoration(color: (tipe == 'kabar' ? Colors.orange : primaryTeal).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                              child: Text(tipe == 'kabar' ? 'KABAR' : 'BERITA', style: TextStyle(color: tipe == 'kabar' ? Colors.orange : primaryTeal, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                            ),
                                            if (_userRole == 'super_admin')
                                              IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                icon: Icon(isFeatured ? Icons.star_rounded : Icons.star_outline_rounded, color: isFeatured ? Colors.amber : Colors.grey.shade400, size: 24),
                                                onPressed: () => _toggleFeatured(id, isFeatured),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(item['judul'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark, height: 1.2), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Text(
                                          tipe == 'kabar' ? (item['konten'] ?? '') : (item['sub_judul'] ?? ''), 
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
                      childCount: _announcements.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
    );
  }
}
