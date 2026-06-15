import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class EventListScreen extends StatefulWidget {
  final String userNik;
  const EventListScreen({super.key, required this.userNik});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  List<String> _userRsvps = [];

  @override
  void initState() {
    super.initState();
    _fetchUserRsvps();
  }

  Future<void> _fetchUserRsvps() async {
    final data = await Supabase.instance.client.from('event_rsvp').select('event_id').eq('nik', widget.userNik);
    setState(() => _userRsvps = (data as List).map((e) => e['event_id'].toString()).toList());
  }

  Future<void> _toggleRsvp(String eventId) async {
    try {
      if (_userRsvps.contains(eventId)) {
        await Supabase.instance.client.from('event_rsvp').delete().eq('event_id', eventId).eq('nik', widget.userNik);
      } else {
        await Supabase.instance.client.from('event_rsvp').insert({'event_id': eventId, 'nik': widget.userNik});
      }
      _fetchUserRsvps();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF0F766E);
    const Color textDark = Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
        title: const Text('ACARA WARGA', style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client.from('events').stream(primaryKey: ['id']).order('event_date', ascending: true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final events = snapshot.data ?? [];
          if (events.isEmpty) return const Center(child: Text('Belum ada acara mendatang.'));

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final ev = events[index];
              final isRsvped = _userRsvps.contains(ev['id'].toString());
              final date = DateFormat('EEEE, d MMM yyyy').format(DateTime.parse(ev['event_date']));

              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8))]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ev['image_url'] != null)
                      ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), child: Image.network(ev['image_url'], height: 160, width: double.infinity, fit: BoxFit.cover)),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(ev['title'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textDark))),
                              const SizedBox(width: 8),
                              _buildStatusBadge(ev['status']),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildIconInfo(Icons.calendar_today_rounded, date, Colors.blue),
                          const SizedBox(height: 6),
                          _buildIconInfo(Icons.access_time_rounded, ev['event_time'], Colors.orange),
                          const SizedBox(height: 6),
                          _buildIconInfo(Icons.location_on_rounded, ev['location'], Colors.red),
                          const SizedBox(height: 16),
                          Text(ev['description'] ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5)),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _toggleRsvp(ev['id'].toString()),
                                  icon: Icon(isRsvped ? Icons.check_circle : Icons.add_circle_outline, size: 18),
                                  label: Text(isRsvped ? 'SAYA HADIR' : 'IKUT ACARA'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isRsvped ? Colors.green : primaryTeal,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                onPressed: () async {
                                  String phone = ev['coordinator_phone'].toString().replaceAll(RegExp(r'[^0-9]'), '');
                                  
                                  // JURUS SAKTI: Normalisasi nomor ke format Internasional (+62)
                                  if (phone.startsWith('0')) {
                                    phone = '62${phone.substring(1)}';
                                  } else if (phone.startsWith('8')) {
                                    phone = '62$phone';
                                  }

                                  final url = Uri.parse("https://wa.me/$phone?text=Halo Panitia, saya ingin bertanya tentang acara ${ev['title']}");
                                  if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                                },
                                icon: const Icon(Icons.chat_bubble_rounded, color: Colors.green),
                                style: IconButton.styleFrom(backgroundColor: Colors.green.withValues(alpha: 0.1), padding: const EdgeInsets.all(12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildIconInfo(IconData icon, String text, Color color) {
    return Row(children: [Icon(icon, size: 14, color: color), const SizedBox(width: 8), Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))]);
  }

  Widget _buildStatusBadge(String status) {
    Color col = status == 'aktif' ? Colors.green : Colors.grey;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: col.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(status.toUpperCase(), style: TextStyle(color: col, fontSize: 9, fontWeight: FontWeight.bold)));
  }
}
