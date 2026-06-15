import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnnouncementDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const AnnouncementDetailScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    const Color textDark = Color(0xFF1E293B);
    const Color primaryTeal = Color(0xFF0F766E);
    
    // PARSE JAM LOKAL HP
    final DateTime localTime = DateTime.parse(data['created_at']).toLocal();
    final String date = DateFormat('EEEE, d MMMM yyyy, HH:mm').format(localTime);

    final String? imageUrl = data['file_url'];
    final String tipe = data['tipe'] ?? 'kabar';

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // APP BAR DENGAN FOTO (Jika ada)
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
                  // LABEL TIPE
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
                  
                  // JUDUL
                  Text(
                    data['judul'] ?? 'Tanpa Judul',
                    style: const TextStyle(
                      fontSize: 26, 
                      fontWeight: FontWeight.w900, 
                      color: textDark,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // TANGGAL & AUTHOR
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
                  
                  // ISI KONTEN
                  Text(
                    data['konten'] ?? '',
                    style: const TextStyle(
                      fontSize: 16, 
                      color: textDark, 
                      height: 1.8,
                      letterSpacing: 0.2,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // VERIFIED BY ADMIN
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
                            Text('Administrator / RT 01', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textDark)),
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
