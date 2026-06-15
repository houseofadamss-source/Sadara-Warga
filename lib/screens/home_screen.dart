import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'admin_dashboard_screen.dart';
import 'profile_screen.dart';
import 'add_report_screen.dart';
import 'report_history_screen.dart';
import 'announcement_detail_screen.dart';
import 'iuran_screen.dart';
import 'umkm_list_screen.dart';
import 'event_list_screen.dart'; 
import 'financial_report_screen.dart'; 
import 'surat_menu_screen.dart'; 
import 'pesan_placeholder_screen.dart'; // Import Baru

const Color primaryTeal = Color(0xFF0F766E);
const Color textDark = Color(0xFF1E293B);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  
  List<Map<String, dynamic>> _announcements = [];
  List<Map<String, dynamic>> _featuredUmkm = []; // Top 3 UMKM
  List<Map<String, dynamic>> _upcomingEvents = []; // Acara mendatang
  Map<String, dynamic>? _latestReport; // Laporan Keuangan
  bool _isLoadingNews = true;
  bool _isLoadingUmkm = true;
  bool _isLoadingEvents = true;
  RealtimeChannel? _syncChannel;

  String _userName = 'Warga';
  String _userRole = 'warga';
  String _userNik = '-';
  String _userHp = '-';
  String _userAlamat = '-';
  String _userEmail = '-';
  String _userFoto = '';
  bool _isLoadingName = true;

  final List<Map<String, String>> _banners = [
    {
      'title': 'Kerja Bakti Minggu Ini',
      'desc': 'Bersama membersihkan lingkungan RT 01 jam 07:00 WIB.',
      'image': 'https://images.unsplash.com/photo-1591510319741-60281691a53b?w=800&auto=format&fit=crop&q=60',
    },
    {
      'title': 'Layanan Posyandu',
      'desc': 'Jadwal rutin posyandu balita di Balai Warga besok pagi.',
      'image': 'https://images.unsplash.com/photo-1584362946521-4c1980795a44?w=800&auto=format&fit=crop&q=60',
    },
  ];

  @override
  void initState() {
    super.initState();
    // JURUS ANTI-LAG: Gunakan scheduleMicrotask atau timer minimal agar build frame utama kelar dulu
    Future.microtask(() {
      if (mounted) {
        _fetchUserData();
        _initManualSync();
        _fetchFeaturedUmkm(); 
        _fetchUpcomingEvents(); 
      }
    });
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _bannerTimer?.cancel();
    _syncChannel?.unsubscribe();
    super.dispose();
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    if (_upcomingEvents.length > 1) {
      _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (_bannerController.hasClients) {
          int nextItem = _bannerController.page!.toInt() + 1;
          if (nextItem >= _upcomingEvents.length) nextItem = 0;
          _bannerController.animateToPage(nextItem, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
        }
      });
    }
  }

  Future<void> _fetchFeaturedUmkm() async {
    try {
      final data = await Supabase.instance.client
          .from('umkm')
          .select()
          .eq('status', 'approved')
          .eq('is_weekly_featured', true)
          .limit(3);
      
      if (mounted) {
        setState(() {
          _featuredUmkm = List<Map<String, dynamic>>.from(data);
          _isLoadingUmkm = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingUmkm = false);
    }
  }

  Future<void> _fetchUpcomingEvents() async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final data = await Supabase.instance.client
          .from('events')
          .select()
          .gte('event_date', today)
          .eq('status', 'aktif')
          .order('event_date', ascending: true)
          .limit(3);
      
      if (mounted) {
        setState(() {
          _upcomingEvents = List<Map<String, dynamic>>.from(data);
          _isLoadingEvents = false;
        });
        _startBannerTimer();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingEvents = false);
    }
  }

  Future<void> _fetchLatestFinancialReport() async {
    try {
      final data = await Supabase.instance.client
          .from('kas_rt')
          .select()
          .eq('is_published', true)
          .maybeSingle();
      
      if (mounted) setState(() => _latestReport = data);
    } catch (e) { /* ignore */ }
  }

  void _initManualSync() async {
    try {
      final initial = await Supabase.instance.client.from('announcements').select().order('created_at', ascending: false).limit(10);
      if (mounted) setState(() { _announcements = List<Map<String, dynamic>>.from(initial); _isLoadingNews = false; });

      _fetchLatestFinancialReport(); 

      _syncChannel = Supabase.instance.client.channel('global_sync');
      _syncChannel!.onBroadcast(
        event: 'DELETE_ANNOUNCEMENT',
        callback: (payload) {
          final String idToDelete = payload['id'].toString();
          if (mounted) {
            setState(() {
              _announcements.removeWhere((item) => item['id'].toString() == idToDelete);
            });
          }
        },
      ).subscribe();
      
      Supabase.instance.client.channel('public:announcements').onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'announcements',
        callback: (payload) {
          if (payload.eventType == PostgresChangeEvent.delete) {
             final id = payload.oldRecord['id'].toString();
             if (mounted) setState(() { _announcements.removeWhere((it) => it['id'].toString() == id); });
          } else if (payload.eventType == PostgresChangeEvent.insert) {
             if (mounted) setState(() { _announcements.insert(0, payload.newRecord); });
          }
        }
      ).subscribe();
    } catch (e) {
      if (mounted) setState(() => _isLoadingNews = false);
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nik = prefs.getString('userNik');
      if (nik != null && nik.isNotEmpty) {
        final data = await Supabase.instance.client.from('users').select().eq('nik', nik).maybeSingle();
        if (data != null && mounted) {
          setState(() {
            _userName = data['nama_lengkap'] ?? 'Warga';
            _userRole = (data['role'] ?? 'warga').toString().toLowerCase();
            _userNik = data['nik'] ?? '-';
            _userHp = data['nomor_hp'] ?? '-';
            _userAlamat = data['alamat'] ?? '-';
            _userEmail = data['email'] ?? '-';
            _userFoto = data['foto_profil'] ?? '';
            _isLoadingName = false;
          });
          await prefs.setString('userName', _userName);
          await prefs.setString('userRole', _userRole);
        }
      }
      if (mounted) setState(() => _isLoadingName = false);
    } catch (e) { if (mounted) setState(() => _isLoadingName = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex == 3 ? 1 : (_selectedIndex == 1 ? 2 : (_selectedIndex == 2 ? 3 : 0)),
        children: [
          _buildBerandaTab(),
          ProfileScreen(
            userData: {'nama_lengkap': _userName, 'email': _userEmail, 'nomor_hp': _userHp, 'nik': _userNik, 'alamat': _userAlamat, 'foto_profil': _userFoto},
            onBack: () => setState(() => _selectedIndex = 0),
          ),
          ReportHistoryScreen(nik: _userNik, onBack: () => setState(() => _selectedIndex = 0)),
          const PesanPlaceholderScreen(),
        ],
      ),
      bottomNavigationBar: _buildFloatingGlassNav(),
    );
  }

  Widget _buildBerandaTab() {
    return SafeArea(bottom: false, child: RefreshIndicator(
      onRefresh: () async { await _fetchUserData(); _initManualSync(); await _fetchFeaturedUmkm(); await _fetchUpcomingEvents(); },
      child: SingleChildScrollView(physics: const BouncingScrollPhysics(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(24, 20, 24, 0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Selamat Datang,', style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
            _isLoadingName ? Container(width: 100, height: 22, color: Colors.black12) : Text(_userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark)),
          ]),
          GestureDetector(onTap: () => setState(() => _selectedIndex = 3), child: CircleAvatar(radius: 22, backgroundColor: primaryTeal, backgroundImage: _userFoto.isNotEmpty ? NetworkImage(_userFoto) : null, child: _userFoto.isEmpty ? const Icon(Icons.person, color: Colors.white) : null)),
        ])),
        const SizedBox(height: 16),
        if (_userRole == 'super_admin') _buildAdminShortcut(),
        _buildBannerSection(),
        if (_latestReport != null) _buildFinancialBanner(),
        const Padding(padding: EdgeInsets.fromLTRB(24, 24, 24, 12), child: Text('Layanan Warga', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark))),
        _buildServicesGrid(),
        if (_upcomingEvents.isNotEmpty) ...[
          const Padding(padding: EdgeInsets.fromLTRB(24, 24, 24, 12), child: Text('Acara Mendatang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark))),
          _buildUpcomingEvents(),
        ],
        const Padding(padding: EdgeInsets.fromLTRB(24, 24, 24, 12), child: Text('Unggulan Minggu Ini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark))),
        _buildFeaturedUmkm(),
        const Padding(padding: EdgeInsets.fromLTRB(24, 24, 24, 12), child: Text('Kabar Lingkungan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark))),
        _buildNewsList(),
        const SizedBox(height: 120),
      ])),
    ));
  }

  Widget _buildAdminShortcut() {
    return Container(margin: const EdgeInsets.fromLTRB(24, 8, 24, 24), padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: const LinearGradient(colors: [primaryTeal, Color(0xFF0D9488)]), borderRadius: BorderRadius.circular(24)), child: Row(children: [
      const Icon(Icons.admin_panel_settings, color: Colors.white, size: 40),
      const SizedBox(width: 16),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Admin Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text('Kontrol warga & layanan RT', style: TextStyle(color: Colors.white70, fontSize: 12))])),
      ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminDashboardScreen())), style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black), child: const Text('BUKA')),
    ]));
  }

  Widget _buildBannerSection() {
    if (_isLoadingEvents) return Container(height: 180, margin: const EdgeInsets.symmetric(horizontal: 24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)), child: const Center(child: CircularProgressIndicator()));
    
    if (_upcomingEvents.isEmpty) {
      return Container(
        height: 160, margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [primaryTeal, Color(0xFF0D9488)]), borderRadius: BorderRadius.circular(28)),
        child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.event_available_rounded, color: Colors.white, size: 40), SizedBox(height: 12), Text('Belum ada acara dalam waktu dekat', style: TextStyle(color: Colors.white70, fontSize: 12))])),
      );
    }

    return SizedBox(height: 180, child: PageView.builder(controller: _bannerController, itemCount: _upcomingEvents.length, itemBuilder: (context, index) {
      final ev = _upcomingEvents[index];
      return GestureDetector(
        onTap: () => _showEventDetail(ev),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24), 
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28), 
            image: ev['image_url'] != null ? DecorationImage(image: NetworkImage(ev['image_url']!), fit: BoxFit.cover) : null,
            color: primaryTeal
          ), 
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28), 
              gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent])
            ), 
            padding: const EdgeInsets.all(20), 
            child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(8)), child: const Text('ACARA WARGA', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold))),
              const SizedBox(height: 8),
              Text(ev['title']!, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), 
              Text('${ev['event_date']} • ${ev['event_time']}', style: const TextStyle(color: Colors.white70, fontSize: 12))
            ])
          )
        ),
      );
    }));
  }

  void _showEventDetail(Map<String, dynamic> ev) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        if (ev['image_url'] != null)
                          ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), child: Image.network(ev['image_url'], height: 300, width: double.infinity, fit: BoxFit.cover))
                        else
                          Container(height: 200, width: double.infinity, decoration: const BoxDecoration(color: primaryTeal, borderRadius: BorderRadius.vertical(top: Radius.circular(32))), child: const Icon(Icons.event_available_rounded, color: Colors.white, size: 60)),
                        Positioned(top: 20, right: 20, child: CircleAvatar(backgroundColor: Colors.black.withValues(alpha: 0.3), child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)))),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Text('AKTIF', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold))),
                            Text(DateFormat('EEEE, d MMMM yyyy').format(DateTime.parse(ev['event_date'])), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ]),
                          const SizedBox(height: 16),
                          Text(ev['title'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark)),
                          const SizedBox(height: 20),
                          _buildDetailInfo(Icons.access_time_rounded, 'Waktu Pelaksanaan', ev['event_time'], Colors.blue),
                          const SizedBox(height: 16),
                          _buildDetailInfo(Icons.location_on_rounded, 'Lokasi Kegiatan', ev['location'], Colors.red),
                          const SizedBox(height: 16),
                          _buildDetailInfo(Icons.person_pin_rounded, 'Penanggung Jawab', ev['coordinator_name'] ?? '-', Colors.orange),
                          const SizedBox(height: 24),
                          const Text('DESKRIPSI ACARA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                          const SizedBox(height: 12),
                          Text(ev['description'] ?? 'Tidak ada deskripsi tambahan.', style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.6)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    String phone = ev['coordinator_phone'].toString().replaceAll(RegExp(r'[^0-9]'), '');
                    if (phone.startsWith('0')) phone = '62${phone.substring(1)}';
                    else if (phone.startsWith('8')) phone = '62$phone';
                    final url = Uri.parse("https://wa.me/$phone?text=Halo Panitia, saya ingin bertanya tentang acara ${ev['title']}");
                    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.chat_bubble_rounded),
                  label: const Text('HUBUNGI PANITIA (WA)', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailInfo(IconData icon, String label, String value, Color color) {
    return Row(children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 18)),
      const SizedBox(width: 16),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark))]),
    ]);
  }

  Widget _buildFinancialBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.blue.withValues(alpha: 0.1))),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.blue)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Laporan Keuangan RT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text('Saldo Kas: Rp ${(_latestReport!['total_saldo'] ?? 0).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}', style: const TextStyle(fontSize: 12, color: Colors.grey))])),
          TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const FinancialReportScreen())), child: const Text('LIHAT', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildServicesGrid() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      _buildServiceItem('Lapor', Icons.campaign_rounded, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (c) => AddReportScreen(nik: _userNik, nama: _userName)))),
      _buildServiceItem('Acara', Icons.event_rounded, Colors.redAccent, () => Navigator.push(context, MaterialPageRoute(builder: (c) => EventListScreen(userNik: _userNik)))),
      _buildServiceItem('Surat', Icons.description_rounded, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (c) => SuratMenuScreen(nik: _userNik, nama: _userName)))),
      _buildServiceItem('Iuran', Icons.account_balance_wallet_rounded, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (c) => IuranScreen(userNik: _userNik, userRole: _userRole)))),
      _buildServiceItem('UMKM', Icons.store_rounded, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (c) => UmkmListScreen(userNik: _userNik)))),
    ]));
  }

  Widget _buildUpcomingEvents() {
    if (_isLoadingEvents) return const Center(child: CircularProgressIndicator());
    
    return SizedBox(height: 130, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: _upcomingEvents.length, itemBuilder: (context, index) {
      final ev = _upcomingEvents[index];
      final date = DateFormat('d MMM').format(DateTime.parse(ev['event_date']));
      return GestureDetector(
        onTap: () => _showEventDetail(ev),
        child: Container(
          width: 260, margin: const EdgeInsets.symmetric(horizontal: 8), 
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
          child: Row(children: [
            Container(width: 50, height: 50, decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(date.split(' ')[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryTeal)), Text(date.split(' ')[1], style: const TextStyle(fontSize: 10, color: primaryTeal))])),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(ev['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark), maxLines: 1, overflow: TextOverflow.ellipsis), const SizedBox(height: 4), Text(ev['location'], style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis), const SizedBox(height: 4), Text(ev['event_time'], style: const TextStyle(fontSize: 11, color: primaryTeal, fontWeight: FontWeight.bold))])),
          ]),
        ),
      );
    }));
  }

  Widget _buildServiceItem(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Column(mainAxisSize: MainAxisSize.min, children: [Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]), child: Icon(icon, color: color, size: 26)), const SizedBox(height: 8), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))]));
  }

  Widget _buildFeaturedUmkm() {
    if (_isLoadingUmkm) return const Center(child: CircularProgressIndicator());
    if (_featuredUmkm.isEmpty) return const Center(child: Text('Belum ada UMKM unggulan.'));
    
    return SizedBox(height: 200, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: _featuredUmkm.length, itemBuilder: (context, index) {
      final ad = _featuredUmkm[index];
      return Container(width: 280, margin: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), child: Image.network(ad['foto_url']!, height: 110, width: double.infinity, fit: BoxFit.cover)),
        Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(ad['nama_bisnis']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text(ad['jenis_dagangan']!, style: const TextStyle(color: primaryTeal, fontSize: 9, fontWeight: FontWeight.bold)))]),
          const SizedBox(height: 4),
          Text(ad['produk_utama']!, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
      ]));
    }));
  }

  Widget _buildNewsList() {
    if (_isLoadingNews) return const Center(child: CircularProgressIndicator());
    if (_announcements.isEmpty) return const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('Belum ada kabar lingkungan')));
    return Column(children: _announcements.map((item) {
        final DateTime localTime = DateTime.parse(item['created_at']).toLocal();
        final String timeStr = DateFormat('EEEE, d MMM, HH:mm').format(localTime);
        return _buildNewsItem(context, item['judul'] ?? '', timeStr, item);
    }).toList());
  }

  Widget _buildNewsItem(BuildContext context, String title, String time, Map<String, dynamic> data) {
    final String? imageUrl = data['file_url'];
    final String? blogUrl = data['blog_url'];
    final String tipe = data['tipe'] ?? 'kabar';
    return GestureDetector(
      onTap: () async {
        if (tipe == 'berita' && blogUrl != null && blogUrl.trim().isNotEmpty) {
          final Uri url = Uri.parse(blogUrl);
          if (await canLaunchUrl(url)) { await launchUrl(url, mode: LaunchMode.externalApplication); }
          else { if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (c) => AnnouncementDetailScreen(data: data))); }
        } else { Navigator.push(context, MaterialPageRoute(builder: (c) => AnnouncementDetailScreen(data: data))); }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 5))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (imageUrl != null && imageUrl.isNotEmpty) ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), child: Image.network(imageUrl, height: 160, width: double.infinity, fit: BoxFit.cover)),
          Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: (tipe == 'kabar' ? Colors.orange : primaryTeal).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(tipe == 'kabar' ? 'KABAR INSTANT' : 'BERITA WARGA', style: TextStyle(color: tipe == 'kabar' ? Colors.orange : primaryTeal, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
              const Spacer(),
              if (tipe == 'berita') const Icon(Icons.open_in_new_rounded, size: 14, color: primaryTeal),
              const SizedBox(width: 8),
              Text(time, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ]),
            const SizedBox(height: 12),
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B), height: 1.4)),
            const SizedBox(height: 4),
            Text(tipe == 'kabar' ? (data['konten'] ?? '') : (data['sub_judul'] ?? ''), maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            const Row(children: [Icon(Icons.verified_user_rounded, size: 14, color: Colors.blue), SizedBox(width: 6), Text('Administrator', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue))]),
          ])),
        ]),
      ),
    );
  }

  Widget _buildFloatingGlassNav() {
    return Container(height: 90, padding: const EdgeInsets.fromLTRB(24, 0, 24, 20), child: ClipRRect(borderRadius: BorderRadius.circular(30), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withValues(alpha: 0.3))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_buildNavItem(Icons.home_filled, 'Beranda', 0), _buildNavItem(Icons.history_toggle_off, 'Aktivitas', 1), _buildNavItem(Icons.chat_bubble_outline_rounded, 'Pesan', 2), _buildNavItem(Icons.person_outline_rounded, 'Akun', 3)])))));
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool sel = _selectedIndex == index; Color col = sel ? primaryTeal : const Color(0xFF94A3B8);
    return GestureDetector(onTap: () => setState(() => _selectedIndex = index), child: Container(color: Colors.transparent, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: col, size: 26), const SizedBox(height: 4), Text(label, style: TextStyle(color: col, fontSize: 10, fontWeight: sel ? FontWeight.bold : FontWeight.normal))])));
  }
}
