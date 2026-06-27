import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/announcement_entity.dart';
import '../bloc/announcement_bloc.dart';
import '../bloc/announcement_event.dart';
import '../bloc/announcement_state.dart';
import 'announcement_detail_page.dart';

class AnnouncementListPage extends StatelessWidget {
  final String tipe;
  const AnnouncementListPage({super.key, required this.tipe});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AnnouncementBloc>()..add(FetchAnnouncementsRequested(tipe)),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(tipe == 'kabar' ? 'Kabar Lingkungan' : 'Berita Terkini',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: BlocBuilder<AnnouncementBloc, AnnouncementState>(
          builder: (context, state) {
            if (state is AnnouncementLoading) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)));
            }

            List<AnnouncementEntity> items = [];
            if (state is AnnouncementsLoaded) {
              items = state.announcements;
            }

            if (items.isEmpty) {
              return Center(
                child: Text('Belum ada ${tipe == 'kabar' ? 'kabar' : 'berita'}.',
                    style: const TextStyle(color: Colors.grey)),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _buildCard(context, items[index]);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, AnnouncementEntity item) {
    final bool isBerita = item.tipe == 'berita';
    final String date = DateFormat('d MMMM yyyy').format(item.createdAt.toLocal());

    return GestureDetector(
      onTap: () {
        if (isBerita) {
          launchUrl(Uri.parse(item.konten), mode: LaunchMode.inAppBrowserView);
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (c) => AnnouncementDetailPage(announcement: item)));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.fileUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Image.network(item.fileUrl!, height: 180, width: double.infinity, fit: BoxFit.cover),
              ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 6),
                      Text(date, style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.judul,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B), height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isBerita ? (item.subJudul ?? '') : item.konten,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
