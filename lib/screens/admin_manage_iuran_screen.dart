import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminManageIuranScreen extends StatefulWidget {
  const AdminManageIuranScreen({super.key});

  @override
  State<AdminManageIuranScreen> createState() => _AdminManageIuranScreenState();
}

class _AdminManageIuranScreenState extends State<AdminManageIuranScreen> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _createIuran() async {
    if (_nameCtrl.text.isEmpty || _amountCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama dan Nominal wajib diisi!')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('iuran_kategori').insert({
        'nama_iuran': _nameCtrl.text.trim(),
        'nominal': double.parse(_amountCtrl.text.replaceAll('.', '')),
        'deskripsi': _descCtrl.text.trim(),
        'is_active': true,
      });

      if (mounted) {
        _nameCtrl.clear();
        _amountCtrl.clear();
        _descCtrl.clear();
        Navigator.pop(context); // Tutup modal
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kategori iuran berhasil dibuat!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: const BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.all(Radius.circular(10))))),
            const SizedBox(height: 24),
            const Text('Buat Tagihan Iuran', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildField('Nama Iuran', 'Contoh: Iuran Sampah Juli', _nameCtrl),
            const SizedBox(height: 16),
            _buildField('Nominal (Rp)', 'Contoh: 25000', _amountCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildField('Deskripsi (Opsional)', 'Detail iuran...', _descCtrl, maxLines: 2),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createIuran,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('BUAT TAGIHAN SEKARANG', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String hint, TextEditingController ctrl, {TextInputType? keyboardType, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl, keyboardType: keyboardType, maxLines: maxLines,
          decoration: InputDecoration(hintText: hint, filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200))),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color textDark = Color(0xFF1E293B);
    const Color primaryTeal = Color(0xFF0F766E);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
        title: const Text('MANAJEMEN IURAN', style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client.from('iuran_kategori').stream(primaryKey: ['id']).order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final categories = snapshot.data ?? [];

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DAFTAR TAGIHAN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
                      const SizedBox(height: 8),
                      Text(
                        'Buat kategori iuran rutin atau sumbangan insidental. Nonaktifkan tagihan yang sudah tidak berlaku agar tidak muncul di warga.',
                        style: TextStyle(fontSize: 13, color: const Color(0xFF64748B).withValues(alpha: 0.8), height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              if (categories.isEmpty)
                const SliverFillRemaining(child: Center(child: Text('Belum ada tagihan iuran.')))
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final cat = categories[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(cat['nama_iuran'], style: const TextStyle(fontWeight: FontWeight.bold, color: textDark)),
                            subtitle: Text('Rp ${cat['nominal'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}', style: const TextStyle(color: primaryTeal, fontWeight: FontWeight.bold)),
                            trailing: Switch(
                              value: cat['is_active'] ?? true,
                              activeColor: primaryTeal,
                              onChanged: (val) async {
                                await Supabase.instance.client.from('iuran_kategori').update({'is_active': val}).eq('id', cat['id']);
                              },
                            ),
                          ),
                        );
                      },
                      childCount: categories.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddModal,
        backgroundColor: primaryTeal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('BUAT TAGIHAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
