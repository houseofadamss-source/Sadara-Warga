import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/finance_entities.dart';

abstract class FinanceRepository {
  Stream<KasEntity> watchKasStatus();
  Stream<List<BillEntity>> watchActiveBills(String userId);
  Stream<List<PaymentEntity>> watchUserPayments(String userId);
  Stream<List<ExpenseEntity>> watchExpenses();
  Stream<List<PaymentEntity>> watchPendingPayments();

  Future<Either<Failure, Unit>> submitPayment({
    required String userId,
    required String kategoriId,
    required int amount,
    required int bulan,
    required int tahun,
    required String buktiPath,
  });

  Future<Either<Failure, Unit>> updatePaymentStatus(String paymentId, String status);
  
  Future<Either<Failure, Unit>> addExpense({
    required String judul,
    required int nominal,
    required DateTime tanggal,
  });

  Future<Either<Failure, Unit>> updateManualSaldo(int newSaldo);

  Future<Either<Failure, Unit>> addBillCategory({
    required String nama,
    required int nominal,
  });

  Future<Either<Failure, Unit>> toggleBillStatus(String id, bool isActive);
}
