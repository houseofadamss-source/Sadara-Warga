import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/finance_models.dart';

abstract class FinanceRemoteDataSource {
  Stream<KasModel> watchKasStatus();
  Stream<List<BillModel>> watchBillCategories();
  Stream<List<PaymentModel>> watchUserPayments(String userId);
  Stream<List<ExpenseModel>> watchExpenses();
  Stream<List<PaymentModel>> watchPendingPayments();

  Future<void> submitPayment({
    required String userId,
    required String kategoriId,
    required int amount,
    required int bulan,
    required int tahun,
    required String buktiPath,
  });

  Future<void> updatePaymentStatus(String paymentId, String status);
  Future<void> addExpense(String judul, int nominal, DateTime tanggal);
  Future<void> updateManualSaldo(int newSaldo);
  Future<void> addBillCategory(String nama, int nominal);
  Future<void> toggleBillStatus(String id, bool isActive);
}

class FinanceRemoteDataSourceImpl implements FinanceRemoteDataSource {
  final SupabaseClient client;

  FinanceRemoteDataSourceImpl(this.client);

  @override
  Stream<KasModel> watchKasStatus() {
    return client
        .from('kas_rt')
        .stream(primaryKey: ['id'])
        .limit(1)
        .map((list) => list.isEmpty ? const KasModel(totalSaldo: 0) : KasModel.fromJson(list[0]));
  }

  @override
  Stream<List<BillModel>> watchBillCategories() {
    return client
        .from('iuran_kategori')
        .stream(primaryKey: ['id'])
        .map((list) => list.map((e) => BillModel.fromJson(e)).toList());
  }

  @override
  Stream<List<PaymentModel>> watchUserPayments(String userId) {
    return client
        .from('pembayaran_iuran')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((list) => PaymentModel.fromJsonList(list));
  }

  @override
  Stream<List<ExpenseModel>> watchExpenses() {
    return client
        .from('pengeluaran_kas')
        .stream(primaryKey: ['id'])
        .order('tanggal_pengeluaran', ascending: false)
        .map((list) => ExpenseModel.fromJsonList(list));
  }

  @override
  Stream<List<PaymentModel>> watchPendingPayments() {
    return client
        .from('pembayaran_iuran')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .map((list) => PaymentModel.fromJsonList(list));
  }

  @override
  Future<void> submitPayment({
    required String userId,
    required String kategoriId,
    required int amount,
    required int bulan,
    required int tahun,
    required String buktiPath,
  }) async {
    final fileName = 'proof_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await client.storage.from('bukti_iuran').upload(fileName, File(buktiPath));
    final publicUrl = client.storage.from('bukti_iuran').getPublicUrl(fileName);

    await client.from('pembayaran_iuran').insert({
      'user_id': userId,
      'kategori_id': kategoriId,
      'jumlah_bayar': amount,
      'bulan': bulan,
      'tahun': tahun,
      'bukti_transfer_url': publicUrl,
      'status': 'pending',
    });
  }

  @override
  Future<void> updatePaymentStatus(String paymentId, String status) async {
    final payment = await client.from('pembayaran_iuran').select().eq('id', paymentId).single();
    final int amount = payment['jumlah_bayar'];

    await client.from('pembayaran_iuran').update({'status': status}).eq('id', paymentId);

    if (status == 'approved') {
      final kasData = await client.from('kas_rt').select().limit(1).maybeSingle();
      if (kasData != null) {
        final int currentSaldo = kasData['total_saldo'] ?? 0;
        await client.from('kas_rt').update({
          'total_saldo': currentSaldo + amount,
          'last_updated': DateTime.now().toIso8601String(),
        }).eq('id', kasData['id']);
      }
    }
  }

  @override
  Future<void> addExpense(String judul, int nominal, DateTime tanggal) async {
    await client.from('pengeluaran_kas').insert({
      'judul_pengeluaran': judul,
      'nominal': nominal,
      'tanggal_pengeluaran': tanggal.toIso8601String(),
    });

    final kasData = await client.from('kas_rt').select().limit(1).maybeSingle();
    if (kasData != null) {
      final int currentSaldo = kasData['total_saldo'] ?? 0;
      await client.from('kas_rt').update({
        'total_saldo': currentSaldo - nominal,
        'last_updated': DateTime.now().toIso8601String(),
      }).eq('id', kasData['id']);
    }
  }

  @override
  Future<void> updateManualSaldo(int newSaldo) async {
    final kasData = await client.from('kas_rt').select().limit(1).maybeSingle();
    if (kasData != null) {
      await client.from('kas_rt').update({
        'total_saldo': newSaldo,
        'last_updated': DateTime.now().toIso8601String(),
      }).eq('id', kasData['id']);
    } else {
      await client.from('kas_rt').insert({
        'total_saldo': newSaldo,
        'is_published': true,
      });
    }
  }

  @override
  Future<void> addBillCategory(String nama, int nominal) async {
    await client.from('iuran_kategori').insert({
      'nama_iuran': nama,
      'nominal': nominal,
      'is_active': true,
    });
  }

  @override
  Future<void> toggleBillStatus(String id, bool isActive) async {
    await client.from('iuran_kategori').update({'is_active': isActive}).eq('id', id);
  }
}
