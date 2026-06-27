import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../domain/entities/announcement_entity.dart';

class AnnouncementDetailPage extends StatelessWidget {
  final AnnouncementEntity announcement;
  const AnnouncementDetailPage({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    const Color textDark = Color(0xFF1E293B);
    const Color primaryTeal = Color(0xFF0F766E);
    
    final String date = DateFormat('EEEE, d MMMM yyyy, HH:mm').format(announcement.createdAt.toLocal());
    final String? imageUrl = announcement.fileUrl;
    final String tipe = announcement.tipe;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: (imageUrl != null && imageUrl.isNotEmpty) ? 300 : 100,
            pinned: true,
            elevation: 0,
            backgroundColor: primaryTeal,
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: (imageUrl != null && imageUrl.isNotEmpty)
                ? Image.network(imageUrl, fit: BoxFit.cover) 
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryTeal, Color(0xFF0D9488)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (tipe == 'kabar' ? Colors.orange : primaryTeal).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tipe == 'kabar' ? 'KABAR INSTANT' : 'BERITA LINGKUNGAN',
                      style: TextStyle(
                        color: tipe == 'kabar' ? Colors.orange : primaryTeal,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  Text(
                    announcement.judul,
                    style: const TextStyle(
                      fontSize: 26, 
                      fontWeight: FontWeight.w900, 
                      color: textDark,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        date,
                        style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                  ),
                  
                  MarkdownBody(
                    data: announcement.konten,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        fontSize: 16, 
                        color: textDark, 
                        height: 1.8,
                        letterSpacing: 0.2,
                      ),
                      strong: const TextStyle(fontWeight: FontWeight.w900, color: textDark),
                      em: const TextStyle(fontStyle: FontStyle.italic),
                      listBullet: const TextStyle(color: primaryTeal, fontSize: 16),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue,
                          radius: 12,
                          child: Icon(Icons.check, size: 14, color: Colors.white),
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Diverifikasi Oleh', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text('Administrator / RT 03', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
