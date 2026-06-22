import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    
    // Hapus semua karakter selain angka
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) return newValue.copyWith(text: '');
    
    final int value = int.parse(cleanText);
    final formatter = NumberFormat.decimalPattern('id');
    String newText = formatter.format(value);
    
    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class AdminFinancialReportScreen extends StatefulWidget {
  const AdminFinancialReportScreen({super.key});

  @override
  State<AdminFinancialReportScreen> createState() => _AdminFinancialReportScreenState();
}

class _AdminFinancialReportScreenState extends State<AdminFinancialReportScreen> {
  final _saldoCtrl = TextEditingController();
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
    final data = await Supabase.instance.client.from('kas_rt').select().limit(1).maybeSingle();
    if (data != null && mounted) {
      setState(() {
        _currentKas = data;
        final formatter = NumberFormat.decimalPattern('id');
        _saldoCtrl.text = formatter.format(data['total_saldo']);
      });
    }
  }

  Future<void> _updateKasSettings() async {
    setState(() => _isLoading = true);
    try {
      final int saldoValue = int.parse(_saldoCtrl.text.replaceAll('.', ''));
      final data = {
        'total_saldo': saldoValue,
        'last_updated': DateTime.now().toIso8601String(),
      };

      if (_currentKas == null) {
        await Supabase.instance.client.from('kas_rt').insert(data);
      } else {
        await Supabase.instance.client.from('kas_rt').update(data).eq('id', _currentKas!['id']);
      }

      await _fetchCurrentKas();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saldo Kas diperbarui!'), backgroundColor: Color(0xFF0F766E)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addExpenditure() async {
    if (_expTitleCtrl.text.isEmpty || _expAmountCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final int amount = int.parse(_expAmountCtrl.text.replaceAll('.', ''));
      final client = Supabase.instance.client;

      // 1. Simpan ke Pengeluaran
      await client.from('pengeluaran_kas').insert({
        'judul_pengeluaran': _expTitleCtrl.text.trim(),
        'nominal': amount,
        'tanggal_pengeluaran': DateTime.now().toIso8601String(),
      });

      // 2. Kurangi Saldo Kas RT
      if (_currentKas != null) {
        final newSaldo = (_currentKas!['total_saldo'] as num) - amount;
        await client.from('kas_rt').update({
          'total_saldo': newSaldo,
          'last_updated': DateTime.now().toIso8601String(),
        }).eq('id', _currentKas!['id']);
      }

      _expTitleCtrl.clear();
      _expAmountCtrl.clear();
      await _fetchCurrentKas();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
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
                  const Text(
                    'Kelola saldo utama dan catat setiap pengeluaran wilayah secara terbuka untuk warga.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SALDO KAS SAAT INI', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        const SizedBox(height: 8),
                        Text(
                          'Rp ${_currentKas != null ? NumberFormat.decimalPattern('id').format(_currentKas!['total_saldo']) : '0'}',
                          style: const TextStyle(color: primaryTeal, fontSize: 32, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildSectionHeader('PENGATURAN SALDO MANUAL'),
                  _buildTextField('Nominal Saldo (Adjustment)', _saldoCtrl, keyboardType: TextInputType.number, isCurrency: true),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateKasSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal, foregroundColor: Colors.white,
                        elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 18)
                      ),
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('UPDATE SALDO UTAMA', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  ),

                  const SizedBox(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('RIWAYAT PENGELUARAN'),
                      TextButton.icon(
                        onPressed: _showExpModal,
                        icon: const Icon(Icons.add_circle_outline, size: 16),
                        label: const Text('TAMBAH BARU', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
        style: const TextStyle(fontWeight: FontWeight.bold),
        decoration: InputDecoration(hintText: hint, filled: true, fillColor: const Color(0xFFF1F5F9), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), contentPadding: const EdgeInsets.all(16)),
      ),
    ]);
  }

  Widget _buildExpList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client.from('pengeluaran_kas').stream(primaryKey: ['id']).order('tanggal_pengeluaran', ascending: false).limit(15),
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
                final date = DateFormat('dd MMM yyyy').format(DateTime.parse(e['tanggal_pengeluaran']));
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.outbox_rounded, color: Colors.red, size: 20)),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e['judul_pengeluaran'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey))])),
                      Text('-Rp ${NumberFormat.decimalPattern('id').format(e['nominal'])}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
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
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (c) => Container(decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))), padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(c).viewInsets.bottom + 32), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)))), const SizedBox(height: 24), const Text('Tambah Pengeluaran Kas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 24), _buildTextField('Keperluan Pengeluaran', _expTitleCtrl, hint: 'Misal: Beli Lampu Jalan'), const SizedBox(height: 20), _buildTextField('Nominal (Rp)', _expAmountCtrl, keyboardType: TextInputType.number, isCurrency: true), const SizedBox(height: 32), SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: _addExpenditure, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0), child: const Text('KONFIRMASI PENGELUARAN', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5))))])));
  }
}
