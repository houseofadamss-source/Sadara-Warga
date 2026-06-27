import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class SOSDetailPage extends StatelessWidget {
  final Map<String, dynamic> sosData;
  const SOSDetailPage({super.key, required this.sosData});

  Future<void> _openGoogleMaps() async {
    final lat = sosData['lokasi_lat'];
    final lng = sosData['lokasi_lng'];
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Gagal membuka Google Maps');
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color textDark = Color(0xFF1E293B);
    final String formattedDate = DateFormat('dd MMMM yyyy, HH:mm:ss').format(DateTime.parse(sosData['created_at']).toLocal());

    return Scaffold(
      backgroundColor: const Color(0xFFFEF2F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('DETAIL DARURAT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.gpp_maybe_rounded, size: 80, color: Colors.red),
                  const SizedBox(height: 24),
                  const Text('WARGA BUTUH BANTUAN!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.red)),
                  const SizedBox(height: 40),
                  
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.05), blurRadius: 20)]),
                    child: Column(
                      children: [
                        _buildInfoRow('Nama Warga', sosData['nama_warga'], Icons.person),
                        const Divider(height: 32),
                        _buildInfoRow('Waktu Sinyal', formattedDate, Icons.access_time),
                        const Divider(height: 32),
                        _buildInfoRow('Koordinat', '${sosData['lokasi_lat']}, ${sosData['lokasi_lng']}', Icons.location_on),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            child: SizedBox(
              width: double.infinity,
              height: 65,
              child: ElevatedButton.icon(
                onPressed: _openGoogleMaps,
                icon: const Icon(Icons.map_rounded, size: 24),
                label: const Text('BUKA LOKASI DI GOOGLE MAPS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: Colors.red.withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: Colors.red, size: 20)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            ],
          ),
        ),
      ],
    );
  }
}
