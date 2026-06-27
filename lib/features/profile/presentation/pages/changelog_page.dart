import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/version_entity.dart';
import '../../domain/repositories/version_repository.dart';

const Color primaryTeal = Color(0xFF0F766E);
const Color textDark = Color(0xFF1E293B);

class ChangelogPage extends StatefulWidget {
  const ChangelogPage({super.key});

  @override
  State<ChangelogPage> createState() => _ChangelogPageState();
}

class _ChangelogPageState extends State<ChangelogPage> {
  bool _isLoading = true;
  List<VersionEntity> _updates = [];
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

      final result = await sl<VersionRepository>().getChangelog();
      
      result.fold(
        (l) {
          if (mounted) setState(() => _isLoading = false);
        },
        (list) {
          if (mounted) {
            setState(() {
              _updates = list;
              _isLoading = false;
            });
          }
        }
      );
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('CATATAN RILIS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5, color: textDark)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
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
                    final bool isCurrent = update.versionName == _currentVersion;

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
          Icon(Icons.history_rounded, size: 64, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('Belum ada catatan rilis di GitHub.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(VersionEntity update, bool isLatest, bool isCurrent) {
    String dateStr = 'Unknown Date';
    try {
      dateStr = DateFormat('d MMMM yyyy').format(DateTime.parse(update.releaseDate));
    } catch (_) {}
    
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
                  color: isLatest ? primaryTeal : Colors.grey.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: isLatest ? [BoxShadow(color: primaryTeal.withOpacity(0.3), blurRadius: 6)] : null,
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: Colors.grey.withOpacity(0.2),
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
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isLatest ? primaryTeal.withOpacity(0.1) : Colors.transparent),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Versi ${update.versionName}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: textDark),
                      ),
                      const Spacer(),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Text('TERPASANG', style: TextStyle(color: Colors.blue, fontSize: 8, fontWeight: FontWeight.bold)),
                        )
                      else if (isLatest)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Text('TERBARU', style: TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(dateStr, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  MarkdownBody(
                    data: update.changelog,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.6),
                      listBullet: const TextStyle(color: primaryTeal),
                      strong: const TextStyle(fontWeight: FontWeight.bold, color: textDark),
                    ),
                  ),
                  if (isLatest && !isCurrent && update.downloadUrl != null) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => launchUrl(Uri.parse(update.downloadUrl!), mode: LaunchMode.externalApplication),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTeal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('UNDUH PEMBARUAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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
