import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'add_event_screen.dart';

class AdminEventsScreen extends StatelessWidget {
  const AdminEventsScreen({super.key});

  Future<void> _deleteEvent(BuildContext context, String id) async {
    try {
      await Supabase.instance.client.from('events').delete().eq('id', id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acara berhasil dihapus')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
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
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
        title: const Text('KELOLA ACARA', style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client.from('events').stream(primaryKey: ['id']).order('event_date', ascending: true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final events = snapshot.data ?? [];

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('PENGATURAN KEGIATAN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
                      const SizedBox(height: 8),
                      Text(
                        'Tambahkan, edit, atau hapus kegiatan warga di sini. Setiap acara yang Anda buat akan muncul di beranda warga.',
                        style: TextStyle(fontSize: 13, color: const Color(0xFF64748B).withValues(alpha: 0.8), height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              if (events.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text('Belum ada acara yang dibuat', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
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
                        final ev = events[index];
                        final date = DateFormat('EEEE, d MMMM yyyy').format(DateTime.parse(ev['event_date']));

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(ev['title'], style: const TextStyle(fontWeight: FontWeight.bold, color: textDark)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Row(children: [const Icon(Icons.calendar_today, size: 14, color: primaryTeal), const SizedBox(width: 8), Text(date, style: const TextStyle(fontSize: 12))]),
                                const SizedBox(height: 4),
                                Row(children: [const Icon(Icons.location_on_outlined, size: 14, color: Colors.orange), const SizedBox(width: 8), Text(ev['location'], style: const TextStyle(fontSize: 12))]),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              itemBuilder: (c) => [
                                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')])),
                                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Colors.red))])),
                              ],
                              onSelected: (val) {
                                if (val == 'edit') {
                                  Navigator.push(context, MaterialPageRoute(builder: (c) => AddEventScreen(eventData: ev)));
                                } else {
                                  _deleteEvent(context, ev['id']);
                                }
                              },
                            ),
                          ),
                        );
                      },
                      childCount: events.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AddEventScreen())),
        backgroundColor: primaryTeal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('ACARA BARU', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
