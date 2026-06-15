import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) return newValue;
    double value = double.parse(newValue.text.replaceAll('.', ''));
    final formatter = NumberFormat.decimalPattern('id');
    String newText = formatter.format(value);
    return newValue.copyWith(text: newText, selection: TextSelection.collapsed(offset: newText.length));
  }
}

class AdminFinancialReportScreen extends StatefulWidget {
  const AdminFinancialReportScreen({super.key});

  @override
  State<AdminFinancialReportScreen> createState() => _AdminFinancialReportScreenState();
}

class _AdminFinancialReportScreenState extends State<AdminFinancialReportScreen> {
  final _saldoCtrl = TextEditingController();
  final _docUrlCtrl = TextEditingController();
  final _expTitleCtrl = TextEditingController();
  final _expAmountCtrl = TextEditingController();
  
  bool _isLoading = false;
  Map<String, dynamic>? _currentKas;

  @override
  void initState() {
    super.initState();
    _fetchCurrentKas();
  }

  Future<void> _fetchCurrentKas() async {
    final data = await Supabase.instance.client.from('kas_rt').select().maybeSingle();
    if (data != null && mounted) {
      setState(() {
        _currentKas = data;
        final formatter = NumberFormat.decimalPattern('id');
        _saldoCtrl.text = formatter.format(data['total_saldo']);
        _docUrlCtrl.text = data['google_doc_url'] ?? '';
      });
    }
  }

  Future<void> _updateKasSettings() async {
    setState(() => _isLoading = true);
    try {
      final double saldoValue = double.parse(_saldoCtrl.text.replaceAll('.', ''));
      final data = {
        'total_saldo': saldoValue,
        'google_doc_url': _docUrlCtrl.text.trim(),
      };

      if (_currentKas == null) {
        await Supabase.instance.client.from('kas_rt').insert(data);
      } else {
        await Supabase.instance.client.from('kas_rt').update(data).eq('id', _currentKas!['id']);
      }

      await _fetchCurrentKas();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengaturan Kas diperbarui!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _publishReport() async {
    if (_currentKas == null) return;
    try {
      await Supabase.instance.client.from('kas_rt').update({'is_published': true}).eq('id', _currentKas!['id']);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Warga telah diberitahu!'), backgroundColor: Colors.blue));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _addExpenditure() async {
    if (_expTitleCtrl.text.isEmpty || _expAmountCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final amount = double.parse(_expAmountCtrl.text.replaceAll('.', ''));
      await Supabase.instance.client.from('pengeluaran_kas').insert({
        'judul': _expTitleCtrl.text.trim(),
        'nominal': amount,
      });

      if (_currentKas != null) {
        final newSaldo = (_currentKas!['total_saldo'] as num) - amount;
        await Supabase.instance.client.from('kas_rt').update({'total_saldo': newSaldo}).eq('id', _currentKas!['id']);
      }

      _expTitleCtrl.clear();
      _expAmountCtrl.clear();
      await _fetchCurrentKas();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color textDark = Color(0xFF1E293B);
    const Color primaryTeal = Color(0xFF0F766E);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
        title: const Text('KAS LINGKUNGAN', style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TRANSPARANSI KAS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
                  const SizedBox(height: 8),
                  Text(
                    'Kelola saldo utama, bagikan laporan detail via Google Sheets, dan catat setiap pengeluaran wilayah secara terbuka.',
                    style: TextStyle(fontSize: 13, color: const Color(0xFF64748B).withValues(alpha: 0.8), height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  
                  // Saldo Minimalist Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: primaryTeal.withValues(alpha: 0.1)),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SALDO KAS SAAT INI', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        const SizedBox(height: 8),
                        Text(
                          'Rp ${_currentKas != null ? NumberFormat.decimalPattern('id').format(_currentKas!['total_saldo']) : '0'}',
                          style: const TextStyle(color: primaryTeal, fontSize: 28, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildSectionHeader('KONFIGURASI'),
                  _buildTextField('Manual Adjustment Saldo', _saldoCtrl, keyboardType: TextInputType.number, isCurrency: true),
                  const SizedBox(height: 16),
                  _buildTextField('Link Laporan (G-Sheets)', _docUrlCtrl, hint: 'https://docs.google.com/spreadsheets/...'),
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateKasSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryTeal, foregroundColor: Colors.white,
                            elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 16)
                          ),
                          child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('SIMPAN PERUBAHAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                        child: IconButton(
                          onPressed: _publishReport,
                          icon: const Icon(Icons.notifications_active_outlined, color: Colors.orange),
                          tooltip: 'Beritahu Warga',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('CATATAN PENGELUARAN'),
                      TextButton.icon(
                        onPressed: _showExpModal,
                        icon: const Icon(Icons.add_circle_outline, size: 16),
                        label: const Text('TAMBAH', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(foregroundColor: primaryTeal),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
          _buildExpList(),
          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1)));

  Widget _buildTextField(String label, TextEditingController ctrl, {TextInputType? keyboardType, String? hint, bool isCurrency = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B))),
      const SizedBox(height: 8),
      TextField(
        controller: ctrl, 
        keyboardType: keyboardType,
        inputFormatters: isCurrency ? [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()] : null,
        decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(fontSize: 12), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200))),
      ),
    ]);
  }

  Widget _buildExpList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client.from('pengeluaran_kas').stream(primaryKey: ['id']).order('tanggal', ascending: false).limit(10),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SliverToBoxAdapter(child: SizedBox());
        
        final exps = snapshot.data ?? [];
        if (exps.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('Belum ada riwayat pengeluaran.', style: TextStyle(color: Colors.grey, fontSize: 12)))),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (c, i) {
                final e = exps[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18)),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e['judul'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text(e['tanggal'], style: const TextStyle(fontSize: 11, color: Colors.grey))])),
                      Text('-Rp ${NumberFormat.decimalPattern('id').format(e['nominal'])}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                );
              },
              childCount: exps.length,
            ),
          ),
        );
      },
    );
  }

  void _showExpModal() {
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (c) => Padding(padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(c).viewInsets.bottom + 24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Tambah Pengeluaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 20), _buildTextField('Keperluan', _expTitleCtrl), const SizedBox(height: 16), _buildTextField('Nominal (Rp)', _expAmountCtrl, keyboardType: TextInputType.number, isCurrency: true), const SizedBox(height: 24), SizedBox(width: double.infinity, height: 54, child: ElevatedButton(onPressed: _addExpenditure, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: const Text('KURANGI SALDO KAS')))])));
  }
}
