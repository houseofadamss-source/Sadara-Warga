import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PesanPlaceholderScreen extends StatelessWidget {
  const PesanPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF0F766E);
    const Color textDark = Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
        title: const Text('PESAN', style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.forum_outlined, size: 64, color: primaryTeal),
              ),
              const SizedBox(height: 32),
              const Text('Fitur Pesan Dalam Pengembangan', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
              const SizedBox(height: 12),
              const Text(
                'Saat ini tim kami sedang membangun sistem chat terintegrasi. Sementara ini, Anda dapat menghubungi Pak RT melalui WhatsApp.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    const String phone = '6281585058720';
                    const String msg = 'Halo Pak RT, saya warga Sadara ingin bertanya mengenai...';
                    final url = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(msg)}");
                    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.chat_bubble_rounded),
                  label: const Text('HUBUNGI VIA WHATSAPP', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
