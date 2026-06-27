import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/emergency_entity.dart';
import '../../domain/usecases/watch_active_contacts.dart';

const Color primaryTeal = Color(0xFF0F766E);
const Color textDark = Color(0xFF1E293B);
const Color errorRed = Color(0xFFDC2626);

class EmergencyPage extends StatelessWidget {
  const EmergencyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Pusat Darurat', style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<EmergencyEntity>>(
        stream: sl<WatchActiveContacts>().call(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: errorRed));
          }
          
          final contacts = snapshot.data ?? [];
          
          if (contacts.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              return _buildEmergencyCard(context, contacts[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.contact_support_rounded, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 24),
            const Text(
              'Belum ada kontak darurat aktif.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pengurus sedang menyiapkan daftar kontak penting untuk wilayah ini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyCard(BuildContext context, EmergencyEntity contact) {
    final String category = contact.category.toLowerCase();
    final String type = contact.actionType;
    
    IconData iconData = Icons.phone_forwarded_rounded;
    Color themeColor = primaryTeal;

    if (category.contains('medis')) {
      iconData = Icons.medical_services_rounded;
      themeColor = Colors.red;
    } else if (category.contains('keamanan') || category.contains('polisi')) {
      iconData = Icons.local_police_rounded;
      themeColor = Colors.blue.shade700;
    } else if (category.contains('kebakaran') || category.contains('damkar')) {
      iconData = Icons.local_fire_department_rounded;
      themeColor = Colors.orange.shade800;
    } else if (category.contains('pengurus') || category.contains('rt')) {
      iconData = Icons.supervisor_account_rounded;
      themeColor = primaryTeal;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: themeColor.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 8))],
        border: Border.all(color: themeColor.withValues(alpha: 0.1), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleAction(contact),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(iconData, color: themeColor, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.title,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contact.description,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(type == 'whatsapp' ? Icons.chat_bubble_rounded : Icons.phone_enabled_rounded, 
                            size: 14, color: themeColor),
                          const SizedBox(width: 6),
                          Text(
                            contact.phone,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: themeColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: themeColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAction(EmergencyEntity contact) async {
    String phone = contact.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final String type = contact.actionType;

    if (type == 'whatsapp') {
      if (phone.startsWith('0')) {
        phone = '62${phone.substring(1)}';
      } else if (phone.startsWith('8')) {
        phone = '62$phone';
      }
      final url = Uri.parse("https://wa.me/$phone?text=HALO DARURAT: Saya membutuhkan bantuan segera.");
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } else {
      final url = Uri.parse("tel:$phone");
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    }
  }
}
