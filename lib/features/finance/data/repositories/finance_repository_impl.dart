import 'package:dartz/dartz.dart';
import 'package:rxdart/rxdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sadarawarga/core/error/failures.dart';
import '../../domain/entities/finance_entities.dart';
import '../../domain/repositories/finance_repository.dart';
import '../datasources/finance_remote_data_source.dart';
import '../models/finance_models.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  final FinanceRemoteDataSource remoteDataSource;
  final SupabaseClient client = Supabase.instance.client;

  FinanceRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<KasEntity> watchKasStatus() {
    return remoteDataSource.watchKasStatus();
  }

  @override
  Stream<List<BillEntity>> watchActiveBills(String userId) {
    return Rx.combineLatest2(
      remoteDataSource.watchBillCategories(),
      userId.isEmpty ? Stream.value(<PaymentEntity>[]) : remoteDataSource.watchUserPayments(userId),
      (List<BillEntity> categories, List<PaymentEntity> payments) {
        final now = DateTime.now();
        
        return categories.map((bill) {
          final int totalPaidForThisBill = payments
              .where((p) => 
                p.kategoriId == bill.id && 
                p.bulan == now.month && 
                p.tahun == now.year && 
                (p.status == 'approved' || p.status == 'pending')
              )
              .fold<int>(0, (sum, p) => sum + p.jumlahBayar);
          
          final int sisa = bill.nominal - totalPaidForThisBill;
          
          return BillEntity(
            id: bill.id,
            namaIuran: bill.namaIuran,
            nominal: bill.nominal,
            isActive: bill.isActive,
            totalPaid: totalPaidForThisBill,
            sisa: sisa > 0 ? sisa : 0,
            isLunas: totalPaidForThisBill >= bill.nominal,
          );
        }).toList();
      },
    );
  }

  @override
  Stream<List<PaymentEntity>> watchUserPayments(String userId) {
    return remoteDataSource.watchUserPayments(userId);
  }

  @override
  Stream<List<ExpenseEntity>> watchExpenses() {
    return remoteDataSource.watchExpenses();
  }

  @override
  Stream<List<PaymentEntity>> watchPendingPayments() {
    return remoteDataSource.watchPendingPayments().switchMap((payments) async* {
       if (payments.isEmpty) {
         yield [];
         return;
       }
       
       final userIds = payments.map((p) => p.userId).toSet().toList();
       final usersData = await client.from('users').select('id, nama_lengkap, alamat').filter('id', 'in', userIds);
       
       final enhanced = payments.map((p) {
         final userData = usersData.firstWhere((u) => u['id'] == p.userId, orElse: () => {});
         return PaymentModel(
           id: p.id,
           userId: p.userId,
           kategoriId: p.kategoriId,
           jumlahBayar: p.jumlahBayar,
           bulan: p.bulan,
           tahun: p.tahun,
           status: p.status,
           createdAt: p.createdAt,
           buktiUrl: p.buktiUrl,
           userName: userData['nama_lengkap'],
           userAddress: userData['alamat'],
         );
       }).toList();
       
       yield enhanced;
    });
  }

  @override
  Future<Either<Failure, Unit>> submitPayment({
    required String userId,
    required String kategoriId,
    required int amount,
    required int bulan,
    required int tahun,
    required String buktiPath,
  }) async {
    try {
      await remoteDataSource.submitPayment(
        userId: userId,
        kategoriId: kategoriId,
        amount: amount,
        bulan: bulan,
        tahun: tahun,
        buktiPath: buktiPath,
      );
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updatePaymentStatus(String paymentId, String status) async {
    try {
      await remoteDataSource.updatePaymentStatus(paymentId, status);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> addExpense({required String judul, required int nominal, required DateTime tanggal}) async {
    try {
      await remoteDataSource.addExpense(judul, nominal, tanggal);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateManualSaldo(int newSaldo) async {
    try {
      await remoteDataSource.updateManualSaldo(newSaldo);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> addBillCategory({required String nama, required int nominal}) async {
    try {
      await remoteDataSource.addBillCategory(nama, nominal);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> toggleBillStatus(String id, bool isActive) async {
    try {
      await remoteDataSource.toggleBillStatus(id, isActive);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
