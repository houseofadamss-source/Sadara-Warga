import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

const Color primaryTeal = Color(0xFF0F766E);
const Color textDark = Color(0xFF1E293B);

class ChangelogScreen extends StatefulWidget {
  const ChangelogScreen({super.key});

  @override
  State<ChangelogScreen> createState() => _ChangelogScreenState();
}

class _ChangelogScreenState extends State<ChangelogScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _updates = [];
  String _currentVersion = "";

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;

      final data = await Supabase.instance.client
          .from('app_updates')
          .select()
          .order('version_code', ascending: false);
      
      if (mounted) {
        setState(() {
          _updates = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Catatan Rilis', style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: primaryTeal))
          : _updates.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _updates.length,
                  itemBuilder: (context, index) {
                    final update = _updates[index];
                    final bool isLatest = index == 0;
                    final bool isCurrent = update['version_name'] == _currentVersion;

                    return _buildTimelineItem(update, isLatest, isCurrent);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text('Belum ada catatan rilis.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> update, bool isLatest, bool isCurrent) {
    final date = DateFormat('d MMMM yyyy').format(DateTime.parse(update['release_date']));
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isLatest ? primaryTeal : Colors.grey.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: isLatest ? [BoxShadow(color: primaryTeal.withValues(alpha: 0.3), blurRadius: 6)] : null,
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 32),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isLatest ? primaryTeal.withValues(alpha: 0.1) : Colors.transparent),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Versi ${update['version_name']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textDark),
                      ),
                      const Spacer(),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Text('TERPASANG', style: TextStyle(color: Colors.blue, fontSize: 8, fontWeight: FontWeight.bold)),
                        )
                      else if (isLatest)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Text('TERBARU', style: TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 16),
                  MarkdownBody(
                    data: update['changelog'] ?? '',
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
                      listBullet: const TextStyle(color: primaryTeal),
                    ),
                  ),
                  if (isLatest && !isCurrent && update['download_url'] != null) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => launchUrl(Uri.parse(update['download_url']), mode: LaunchMode.externalApplication),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTeal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('UPDATE SEKARANG', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
