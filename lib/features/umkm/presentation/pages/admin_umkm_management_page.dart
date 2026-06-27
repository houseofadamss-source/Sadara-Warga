import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../injection_container.dart';
import '../../domain/entities/umkm_entity.dart';
import '../bloc/umkm_bloc.dart';
import '../bloc/umkm_event.dart';
import '../bloc/umkm_state.dart';

const Color primaryTeal = Color(0xFF0F766E);
const Color textDark = Color(0xFF1E293B);

class AdminUmkmManagementPage extends StatelessWidget {
  const AdminUmkmManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<UmkmBloc>(),
      child: const AdminUmkmManagementView(),
    );
  }
}

class AdminUmkmManagementView extends StatefulWidget {
  const AdminUmkmManagementView({super.key});

  @override
  State<AdminUmkmManagementView> createState() => _AdminUmkmManagementViewState();
}

class _AdminUmkmManagementViewState extends State<AdminUmkmManagementView> with SingleTickerProviderStateMixin {
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('MANAJEMEN UMKM',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryTeal,
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: primaryTeal,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(text: 'PENGAJUAN'),
            Tab(text: 'TERVERIFIKASI'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUmkmList(context, 'pending'),
          _buildUmkmList(context, 'approved'),
        ],
      ),
    );
  }

  Widget _buildUmkmList(BuildContext context, String statusFilter) {
    // We use a stream for the list to keep it reactive, but wrap it in Bloc for actions
    return StreamBuilder<List<UmkmEntity>>(
      stream: sl<UmkmBloc>().repository.getUmkmByStatus(statusFilter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final list = snapshot.data ?? [];

        return BlocListener<UmkmBloc, UmkmState>(
          listener: (context, state) {
            if (state is UmkmActionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: primaryTeal));
            } else if (state is UmkmFailure) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
            }
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusFilter == 'pending' ? 'ANTRIAN VERIFIKASI' : 'KATALOG USAHA WARGA',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        statusFilter == 'pending'
                            ? 'Periksa kelengkapan data usaha warga. UMKM yang diverifikasi akan masuk ke daftar fitur UMKM.'
                            : 'Pilih UMKM terbaik untuk ditampilkan di halaman utama Beranda sebagai Unggulan Minggu Ini.',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              if (list.isEmpty)
                SliverFillRemaining(
                  child: Center(
                      child: Text(statusFilter == 'pending' ? 'Tidak ada antrian pendaftaran.' : 'Belum ada usaha yang diverifikasi.',
                          style: const TextStyle(color: Colors.grey, fontSize: 13))),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = list[index];
                        final bool isFeatured = item.isWeeklyFeatured;
                        final bool isPushed = item.isPushedToOsm;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 8))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: item.fotoUrl != null
                                        ? Image.network(item.fotoUrl!, width: 60, height: 60, fit: BoxFit.cover)
                                        : Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey.shade100,
                                            child: const Icon(Icons.store, color: Colors.grey)),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.namaBisnis,
                                            style: const TextStyle(fontWeight: FontWeight.w900, color: textDark, fontSize: 16)),
                                        Text(item.jenisDagangan,
                                            style: const TextStyle(fontSize: 11, color: primaryTeal, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  if (statusFilter == 'approved')
                                    StatefulBuilder(
                                      builder: (context, setTileState) => Switch(
                                        value: item.isWeeklyFeatured,
                                        activeThumbColor: primaryTeal,
                                        activeTrackColor: primaryTeal.withValues(alpha: 0.2),
                                        onChanged: (v) {
                                          context.read<UmkmBloc>().add(ToggleFeaturedRequested(item.id, !v));
                                        },
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(item.deskripsi,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  InkWell(
                                    onTap: () async {
                                      final url = Uri.parse(
                                          "https://www.openstreetmap.org/?mlat=${item.latitude}\u0026mlon=${item.longitude}#map=18/${item.latitude}/${item.longitude}");
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url, mode: LaunchMode.inAppBrowserView);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration:
                                          BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.location_on_rounded, size: 14, color: Colors.blue),
                                          SizedBox(width: 6),
                                          Text('LIHAT TITIK MAPS',
                                              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w900, fontSize: 10)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (statusFilter == 'approved')
                                    Builder(builder: (context) {
                                      final state = context.watch<UmkmBloc>().state;
                                      final bool isBusy = state is UmkmLoading;

                                      return ElevatedButton.icon(
                                        onPressed: (isPushed || isBusy)
                                            ? null
                                            : () => context.read<UmkmBloc>().add(PushToOsmRequested(item)),
                                        icon: Icon(isPushed ? Icons.check_circle : Icons.cloud_done_rounded, size: 14),
                                        label: Text(isPushed ? 'DITERBITKAN' : 'PUSH OSM',
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: isPushed ? Colors.grey.shade100 : Colors.blue.shade600,
                                            foregroundColor: isPushed ? Colors.grey : Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                      );
                                    }),
                                ],
                              ),
                              if (statusFilter == 'pending') ...[
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => context.read<UmkmBloc>().add(UpdateStatusRequested(item.id, 'approved')),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryTeal,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            padding: const EdgeInsets.symmetric(vertical: 12)),
                                        child: const Text('VERIFIKASI USAHA',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => context.read<UmkmBloc>().add(UpdateStatusRequested(item.id, 'rejected')),
                                        style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: const BorderSide(color: Colors.red),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            padding: const EdgeInsets.symmetric(vertical: 12)),
                                        child: const Text('TOLAK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                const SizedBox(height: 12),
                                if (isFeatured)
                                  Row(children: [
                                    const Icon(Icons.auto_awesome, color: Colors.amber, size: 14),
                                    const SizedBox(width: 6),
                                    Text('Sedang tayang di Beranda',
                                        style: TextStyle(
                                            color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 11))
                                  ]),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                      onPressed: () => context.read<UmkmBloc>().add(UpdateStatusRequested(item.id, 'pending')),
                                      child: const Text('BATALKAN VERIFIKASI',
                                          style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold))),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                      childCount: list.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        );
      },
    );
  }
}
