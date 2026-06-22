import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'admin_dashboard_screen.dart';
import 'profile_screen.dart';
import 'add_report_screen.dart';
import 'report_history_screen.dart';
import 'announcement_detail_screen.dart';
import 'iuran_screen.dart';
import 'umkm_list_screen.dart';
import 'event_list_screen.dart'; 
import 'surat_menu_screen.dart'; 
import 'pesan_placeholder_screen.dart';
import 'emergency_screen.dart';
import 'all_kabar_screen.dart';
import 'all_berita_screen.dart';

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
  
  // --- PERSISTENT DATA VARIABLES ---
  List<Map<String, dynamic>> _upcomingEvents = [];
  List<Map<String, dynamic>> _featuredUmkm = [];
  Map<String, dynamic>? _latestKas;
  List<Map<String, dynamic>> _allIuranKategori = [];
  List<Map<String, dynamic>> _allPayments = [];
  
  // --- PERSISTENT STREAMS ---
  late Stream<List<Map<String, dynamic>>> _eventsStream;
  late Stream<List<Map<String, dynamic>>> _umkmStream;
  late Stream<List<Map<String, dynamic>>> _kasStream;
  late Stream<List<Map<String, dynamic>>> _iuranKategoriStream;
  late Stream<List<Map<String, dynamic>>> _pembayaranStream;

  String _userName = 'Warga';
  String _userRole = 'warga';
  String _userNik = '-';
  String _userHp = '-';
  String _userAlamat = '-';
  String _userEmail = '-';
  String _userFoto = '';

  @override
  void initState() {
    super.initState();
    _initStreams(); // Kunci koneksi sejak awal!
    _loadCachedProfile(); 
    Future.microtask(() => _fetchAllDataInParallel());
  }

  void _initStreams() {
    final client = Supabase.instance.client;
    
    _eventsStream = client.from('events').stream(primaryKey: ['id']).eq('status', 'aktif').order('event_date', ascending: true);
    _umkmStream = client.from('umkm').stream(primaryKey: ['id']).eq('is_weekly_featured', true);
    _kasStream = client.from('kas_rt').stream(primaryKey: ['id']).limit(1);
    _iuranKategoriStream = client.from('iuran_kategori').stream(primaryKey: ['id']).eq('is_active', true);
    _pembayaranStream = client.from('pembayaran_iuran').stream(primaryKey: ['id']);
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _userName = prefs.getString('cached_user_name') ?? 'Warga';
          _userFoto = prefs.getString('cached_user_foto') ?? '';
          _userRole = prefs.getString('cached_user_role') ?? 'warga';
        });
      }
    } catch (e) { /* ignore */ }
  }

  Future<void> _fetchAllDataInParallel() async {
    await Future.wait([
      _fetchUserData(),
      _fetchInitialData(),
    ]);
  }

  Future<void> _fetchInitialData() async {
    try {
      final client = Supabase.instance.client;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      // Ambil data awal buat modal pertama kali buka
      final results = await Future.wait([
        client.from('events').select().gte('event_date', today).eq('status', 'aktif').order('event_date').limit(5),
        client.from('umkm').select().eq('status', 'approved').eq('is_weekly_featured', true).limit(5),
        client.from('kas_rt').select().limit(1).maybeSingle(),
      ]);

      if (mounted) {
        setState(() {
          _upcomingEvents = List<Map<String, dynamic>>.from(results[0] as List);
          _featuredUmkm = List<Map<String, dynamic>>.from(results[1] as List);
          _latestKas = results[2] as Map<String, dynamic>?;
        });
        _startBannerTimer();
      }
    } catch (e) { /* ignore */ }
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

  Future<void> _fetchUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final data = await Supabase.instance.client.from('users').select().eq('id', user.id).maybeSingle();
        if (data != null && mounted) {
          final prefs = await SharedPreferences.getInstance();
          setState(() {
            _userName = data['nama_lengkap'] ?? 'Warga';
            _userRole = data['role']?.toString() ?? 'warga';
            _userNik = data['nik'] ?? '-';
            _userHp = data['nomor_hp'] ?? '-';
            _userAlamat = data['alamat'] ?? '-';
            _userEmail = data['email'] ?? '-';
            _userFoto = data['foto_profil'] ?? '';
          });
          await prefs.setString('cached_user_name', _userName);
          await prefs.setString('cached_user_foto', _userFoto);
          await prefs.setString('cached_user_role', _userRole);
        }
      }
    } catch (e) { /* ignore */ }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 19) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex == 3 ? 1 : (_selectedIndex == 1 ? 2 : (_selectedIndex == 2 ? 3 : 0)),
            children: [
              _buildBerandaTab(),
              ProfileScreen(
                userData: {'nama_lengkap': _userName, 'email': _userEmail, 'nomor_hp': _userHp, 'nik': _userNik, 'alamat': _userAlamat, 'foto_profil': _userFoto},
                onBack: () => setState(() => _selectedIndex = 0),
                onRefresh: _fetchUserData, 
              ),
              ReportHistoryScreen(nik: _userNik, onBack: () => setState(() => _selectedIndex = 0)),
              const PesanPlaceholderScreen(),
            ],
          ),
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomNav()),
        ],
      ),
    );
  }

  Widget _buildBerandaTab() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _ModernHeaderDelegate(
            userName: _userName,
            userFoto: _userFoto,
            greeting: _getGreeting(),
            userRole: _userRole,
            onProfileTap: () => setState(() => _selectedIndex = 3),
            onAdminTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminDashboardScreen())),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                _buildBannerSection(),
                _buildFinancialBanner(),
                const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text('Layanan Warga', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark))),
                _buildServicesGrid(),
                _buildEmergencyTrigger(),
                const Padding(padding: EdgeInsets.fromLTRB(0, 40, 0, 16), child: Text('Acara Mendatang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark))),
                _buildUpcomingEvents(),
                const Padding(padding: EdgeInsets.fromLTRB(0, 40, 0, 16), child: Text('Unggulan Minggu Ini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark))),
                _buildFeaturedUmkm(),
                const Padding(padding: EdgeInsets.fromLTRB(0, 40, 0, 16), child: Text('Kabar Lingkungan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark))),
                _buildHorizontalNews('kabar'),
                const Padding(padding: EdgeInsets.fromLTRB(0, 40, 0, 16), child: Text('Berita Terkini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark))),
                _buildHorizontalNews('berita'),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerSection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _eventsStream,
      initialData: _upcomingEvents,
      builder: (context, snapshot) {
        final events = snapshot.data ?? _upcomingEvents;
        if (events.isEmpty) {
          return Container(
            height: 160, 
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [primaryTeal, Color(0xFF0D9488)]), borderRadius: BorderRadius.circular(28)), 
            child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.event_available_rounded, color: Colors.white, size: 40), SizedBox(height: 12), Text('Belum ada acara dalam waktu dekat', style: TextStyle(color: Colors.white70, fontSize: 12))]))
          );
        }

        return SizedBox(
          height: 180, 
          child: PageView.builder(
            controller: _bannerController, 
            itemCount: events.length, 
            itemBuilder: (context, index) {
              final ev = events[index];
              return GestureDetector(
                onTap: () => _showEventDetail(ev),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
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
                    padding: const EdgeInsets.all(24), 
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(8)), child: const Text('ACARA WARGA', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold))),
                      const SizedBox(height: 8),
                      Text(ev['title']!, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), 
                      Text('${ev['event_date']} • ${ev['event_time']}', style: const TextStyle(color: Colors.white70, fontSize: 12))
                    ])
                  )
                ),
              );
            }
          )
        );
      },
    );
  }

  Widget _buildFinancialBanner() {
    final user = Supabase.instance.client.auth.currentUser;
    final now = DateTime.now();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _kasStream,
      builder: (context, snapshotKas) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _iuranKategoriStream,
          builder: (context, snapshotBills) {
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: _pembayaranStream,
              builder: (context, snapshotMyPayments) {
                final saldo = snapshotKas.data?.isNotEmpty == true ? snapshotKas.data![0]['total_saldo'] : (_latestKas?['total_saldo'] ?? 0);
                final allBills = snapshotBills.data ?? [];
                final allPaymentsRaw = snapshotMyPayments.data ?? [];

                final int totalIuranTerkumpul = allPaymentsRaw
                    .where((p) => p['bulan'] == now.month && p['tahun'] == now.year && p['status'] == 'approved')
                    .fold<int>(0, (sum, p) => sum + (p['jumlah_bayar'] as int? ?? 0));

                final myPayments = allPaymentsRaw
                    .where((p) => p['user_id'] == user?.id && p['bulan'] == now.month && p['tahun'] == now.year)
                    .toList();

                final totalUnpaid = allBills.fold<int>(0, (sum, bill) {
                  final int billNominal = bill['nominal'] as int? ?? 0;
                  final int totalPaidForThisBill = myPayments
                      .where((p) => p['kategori_id'] == bill['id'] && (p['status'] == 'approved' || p['status'] == 'pending'))
                      .fold<int>(0, (sum, p) => sum + (p['jumlah_bayar'] as int? ?? 0));
                  
                  final int sisa = billNominal - totalPaidForThisBill;
                  return sum + (sisa > 0 ? sisa : 0);
                });

                return Container(
                  height: 110,
                  margin: const EdgeInsets.only(top: 24),
                  child: PageView(
                    controller: PageController(viewportFraction: 0.9),
                    clipBehavior: Clip.none,
                    children: [
                      _buildBannerCard(
                        icon: Icons.account_balance_wallet_rounded,
                        color: Colors.blue,
                        title: 'Total Saldo Kas RT',
                        value: 'Rp ${NumberFormat('#,###', 'id_ID').format(saldo)}',
                        actionLabel: 'DETAIL',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => IuranScreen(userNik: _userNik, userRole: _userRole))),
                      ),
                      _buildBannerCard(
                        icon: Icons.payments_rounded,
                        color: Colors.teal,
                        title: 'Iuran Terkumpul (Bulan ini)',
                        value: 'Rp ${NumberFormat('#,###', 'id_ID').format(totalIuranTerkumpul)}',
                        actionLabel: 'KAS',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => IuranScreen(userNik: _userNik, userRole: _userRole))),
                      ),
                      _buildBannerCard(
                        icon: Icons.assignment_late_rounded,
                        color: Colors.orange,
                        title: 'Sisa Tagihan Anda',
                        value: 'Rp ${NumberFormat('#,###', 'id_ID').format(totalUnpaid)}',
                        actionLabel: totalUnpaid == 0 ? 'LUNAS' : 'BAYAR',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => IuranScreen(userNik: _userNik, userRole: _userRole))),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBannerCard({required IconData icon, required Color color, required String title, required String value, required String actionLabel, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(24), 
          border: Border.all(color: color.withValues(alpha: 0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: color)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textDark)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Text(actionLabel, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesGrid() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      _buildServiceItem('Lapor', Icons.campaign_rounded, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (c) => AddReportScreen(nik: _userNik, nama: _userName)))),
      _buildServiceItem('Acara', Icons.event_rounded, Colors.redAccent, () => Navigator.push(context, MaterialPageRoute(builder: (c) => EventListScreen(userNik: _userNik)))),
      _buildServiceItem('Surat', Icons.description_rounded, Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (c) => SuratMenuScreen(nik: _userNik, nama: _userName)))),
      _buildServiceItem('Iuran', Icons.account_balance_wallet_rounded, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (c) => IuranScreen(userNik: _userNik, userRole: _userRole)))),
      _buildServiceItem('UMKM', Icons.store_rounded, Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (c) => UmkmListScreen(userNik: _userNik)))),
    ]);
  }

  Widget _buildServiceItem(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Column(children: [
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: color, size: 28)),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textDark)),
    ]));
  }

  Widget _buildEmergencyTrigger() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const EmergencyScreen())),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade600, Colors.red.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emergency_share_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Butuh Bantuan Darurat?',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Hubungi petugas & pengurus sekarang',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingEvents() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _eventsStream,
      initialData: _upcomingEvents,
      builder: (context, snapshot) {
        final events = snapshot.data ?? _upcomingEvents;
        if (events.isEmpty) return const SizedBox(height: 50, child: Center(child: Text('Tidak ada acara terdekat.', style: TextStyle(fontSize: 12, color: Colors.grey))));

        return SizedBox(
          height: 130, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal, 
            itemCount: events.length, 
            itemBuilder: (context, index) {
              final ev = events[index];
              final date = DateFormat('d MMM').format(DateTime.parse(ev['event_date']));
              return GestureDetector(
                onTap: () => _showEventDetail(ev), 
                child: Container(
                  width: 260, 
                  margin: const EdgeInsets.only(right: 16), 
                  padding: const EdgeInsets.all(16), 
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(24), 
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]
                  ), 
                  child: Row(
                    children: [
                      Container(
                        width: 50, height: 50, 
                        decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)), 
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(date.split(' ')[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryTeal)), Text(date.split(' ')[1], style: const TextStyle(fontSize: 10, color: primaryTeal))])
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, 
                          mainAxisAlignment: MainAxisAlignment.center, 
                          children: [
                            Text(ev['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark), maxLines: 1, overflow: TextOverflow.ellipsis), 
                            const SizedBox(height: 4), 
                            Text(ev['location'] ?? '-', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis), 
                            const SizedBox(height: 4), 
                            Text(ev['event_time'] ?? '-', style: const TextStyle(fontSize: 11, color: primaryTeal, fontWeight: FontWeight.bold))
                          ]
                        )
                      ),
                    ]
                  )
                )
              );
            }
          )
        );
      },
    );
  }

  Widget _buildFeaturedUmkm() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _umkmStream,
      initialData: _featuredUmkm,
      builder: (context, snapshot) {
        final rawList = snapshot.data ?? _featuredUmkm;
        final list = rawList.where((u) => u['status'] == 'approved').toList();

        if (list.isEmpty) return const SizedBox(height: 50, child: Center(child: Text('Belum ada UMKM unggulan.', style: TextStyle(fontSize: 12, color: Colors.grey))));

        return SizedBox(
          height: 180, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal, 
            itemCount: list.length, 
            itemBuilder: (context, index) {
              final ad = list[index];
              String displayCategory = (ad['jenis_dagangan'] ?? '-').toString().split('(')[0].trim().toUpperCase();
              
              return GestureDetector(
                onTap: () => _showUmkmDetail(ad), 
                child: Container(
                  width: 220, 
                  margin: const EdgeInsets.only(right: 16), 
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(24), 
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]
                  ), 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), 
                        child: Image.network(ad['foto_url']!, height: 90, width: double.infinity, fit: BoxFit.cover)
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12), 
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, 
                          children: [
                            Text(ad['nama_bisnis']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(ad['produk_utama']!, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), 
                              decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), 
                              child: Text(displayCategory, style: const TextStyle(color: primaryTeal, fontSize: 7, fontWeight: FontWeight.bold))
                            ),
                          ]
                        )
                      )
                    ]
                  )
                )
              );
            }
          )
        );
      },
    );
  }

  void _showUmkmDetail(Map<String, dynamic> umkm) {
    String displayCategory = (umkm['jenis_dagangan'] ?? '-').toString().split('(')[0].trim().toUpperCase();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
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
                        if (umkm['foto_url'] != null)
                          ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), child: Image.network(umkm['foto_url'], height: 280, width: double.infinity, fit: BoxFit.cover))
                        else
                          Container(height: 200, width: double.infinity, decoration: const BoxDecoration(color: primaryTeal, borderRadius: BorderRadius.vertical(top: Radius.circular(32))), child: const Icon(Icons.store_rounded, color: Colors.white, size: 60)),
                        Positioned(top: 20, right: 20, child: CircleAvatar(backgroundColor: Colors.black.withValues(alpha: 0.3), child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)))),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(displayCategory, style: const TextStyle(color: primaryTeal, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5))),
                              const Row(children: [Icon(Icons.stars_rounded, color: Colors.amber, size: 16), SizedBox(width: 4), Text('Unggulan', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12))]),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(umkm['nama_bisnis'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark)),
                          const SizedBox(height: 8),
                          Text(umkm['produk_utama'], style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                          const SizedBox(height: 24),
                          const Text('JAM OPERASIONAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildInfoBadge(Icons.access_time_rounded, '${umkm['jam_buka'] ?? '08:00'} - ${umkm['jam_tutup'] ?? '21:00'}', Colors.blue),
                              const SizedBox(width: 12),
                              _buildInfoBadge(Icons.calendar_today_rounded, umkm['hari_libur'] ?? 'Buka Setiap Hari', Colors.orange),
                            ],
                          ),
                          const SizedBox(height: 32),
                          const Text('TENTANG USAHA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                          const SizedBox(height: 12),
                          MarkdownBody(
                            data: umkm['deskripsi'] ?? 'Tidak ada deskripsi tambahan.',
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.6),
                              listBullet: const TextStyle(fontSize: 14, color: primaryTeal),
                              strong: const TextStyle(fontWeight: FontWeight.bold, color: primaryTeal),
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (umkm['latitude'] != null) ...[
                             _buildDetailInfo(Icons.location_on_rounded, 'Lokasi Usaha', 'Kp. Sinagar RT 03/06', Colors.red),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        String phone = umkm['nomor_wa'].toString().replaceAll(RegExp(r'[^0-9]'), '');
                        if (phone.startsWith('0')) {
                          phone = '62${phone.substring(1)}';
                        } else if (phone.startsWith('8')) {
                          phone = '62$phone';
                        }
                        final url = Uri.parse("https://wa.me/$phone?text=Halo, saya tetangga dari Sadara Warga, mau tanya soal ${umkm['nama_bisnis']}");
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.chat_bubble_rounded),
                      label: const Text('PESAN SEKARANG', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    ),
                  ),
                  if (umkm['latitude'] != null) ...[
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () async {
                        final url = Uri.parse("https://www.openstreetmap.org/?mlat=${umkm['latitude']}&mlon=${umkm['longitude']}#map=18/${umkm['latitude']}/${umkm['longitude']}");
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.inAppBrowserView);
                        }
                      },
                      icon: const Icon(Icons.location_on_rounded, color: Colors.blue),
                      style: IconButton.styleFrom(backgroundColor: Colors.blue.withValues(alpha: 0.1), padding: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildHorizontalNews(String tipe) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('announcements')
          .stream(primaryKey: ['id'])
          .eq('tipe', tipe)
          .order('created_at', ascending: false)
          .limit(6),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()));
        
        final news = snapshot.data ?? [];
        if (news.isEmpty) return const SizedBox(height: 80, child: Center(child: Text('Belum ada kabar.', style: TextStyle(fontSize: 12, color: Colors.grey))));

        final displayList = news.take(5).toList();
        final bool showSeeAll = news.length > 5;

        return SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: displayList.length + (showSeeAll ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == displayList.length) {
                return _buildSeeAllCard(tipe);
              }
              return _buildNewsCard(displayList[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> item) {
    final bool isBerita = item['tipe'] == 'berita';
    return GestureDetector(
      onTap: () {
        if (isBerita) {
          launchUrl(Uri.parse(item['konten']), mode: LaunchMode.inAppBrowserView);
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (c) => AnnouncementDetailScreen(data: item)));
        }
      },
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                image: item['file_url'] != null ? DecorationImage(image: NetworkImage(item['file_url']), fit: BoxFit.cover) : null,
                color: primaryTeal.withValues(alpha: 0.1),
              ),
              child: item['file_url'] == null ? const Icon(Icons.image_outlined, color: primaryTeal) : null,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['judul'] ?? '-',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark, height: 1.3),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isBerita ? (item['sub_judul'] ?? '') : (item['konten'] ?? ''),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeeAllCard(String tipe) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => tipe == 'kabar' ? const AllKabarScreen() : const AllBeritaScreen())),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: primaryTeal.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: primaryTeal.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: primaryTeal, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              'Baca Semua\n${tipe == 'kabar' ? 'Kabar' : 'Berita'}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: primaryTeal),
            ),
          ],
        ),
      ),
    );
  }

  void _showEventDetail(Map<String, dynamic> ev) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Text('AKTIF', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold))),
                              Text(DateFormat('EEEE, d MMMM yyyy').format(DateTime.parse(ev['event_date'])), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
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
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    String phone = ev['coordinator_phone'].toString().replaceAll(RegExp(r'[^0-9]'), '');
                    if (phone.startsWith('0')) {
                      phone = '62${phone.substring(1)}';
                    } else if (phone.startsWith('8')) {
                      phone = '62$phone';
                    }
                    final url = Uri.parse("https://wa.me/$phone?text=Halo Panitia, saya ingin bertanya tentang acara ${ev['title']}");
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
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

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            backgroundColor: Colors.transparent, elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: primaryTeal, unselectedItemColor: const Color(0xFF94A3B8),
            selectedFontSize: 12, unselectedFontSize: 12,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Beranda'),
              BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Aktivitas'),
              BottomNavigationBarItem(icon: Icon(Icons.forum_outlined), label: 'Pesan'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Akun'),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String userName;
  final String userFoto;
  final String greeting;
  final String userRole;
  final VoidCallback onProfileTap;
  final VoidCallback onAdminTap;

  _ModernHeaderDelegate({
    required this.userName,
    required this.userFoto,
    required this.greeting,
    required this.userRole,
    required this.onProfileTap,
    required this.onAdminTap,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double progress = (shrinkOffset / maxExtent).clamp(0.0, 1.0);
    const Color primaryTeal = Color(0xFF0F766E);
    const Color textDark = Color(0xFF1E293B);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15 * progress, sigmaY: 15 * progress),
        child: Container(
          color: Colors.white.withValues(alpha: progress > 0.5 ? 0.85 : progress * 0.85),
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 24, right: 24),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(greeting, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 6),
                        Icon(_getGreetingIcon(), color: Colors.amber, size: 14),
                      ],
                    ),
                    Text(
                      userName, 
                      style: TextStyle(
                        color: textDark, 
                        fontWeight: FontWeight.w900, 
                        fontSize: 24 - (4 * progress),
                        letterSpacing: -0.5
                      )
                    ),
                    if (userRole == 'super_admin')
                      GestureDetector(
                        onTap: onAdminTap,
                        child: Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: primaryTeal, borderRadius: BorderRadius.circular(8)),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text('KELOLA WILAYAH ➔', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: onProfileTap,
                  child: Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: primaryTeal.withValues(alpha: 0.2), width: 2)),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: primaryTeal.withValues(alpha: 0.1),
                      backgroundImage: userFoto.isNotEmpty ? NetworkImage(userFoto) : null,
                      child: userFoto.isEmpty ? const Icon(Icons.person, color: primaryTeal, size: 22) : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 11) return Icons.wb_sunny_rounded;
    if (hour < 15) return Icons.wb_cloudy_rounded;
    if (hour < 19) return Icons.wb_twilight_rounded;
    return Icons.nightlight_round;
  }

  @override
  double get maxExtent => 160;
  @override
  double get minExtent => 85 + kToolbarHeight;
  @override
  bool shouldRebuild(covariant _ModernHeaderDelegate oldDelegate) => true;
}
