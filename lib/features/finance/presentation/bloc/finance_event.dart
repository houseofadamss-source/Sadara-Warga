import 'package:equatable/equatable.dart';

abstract class FinanceEvent extends Equatable {
  const FinanceEvent();

  @override
  List<Object> get props => [];
}

class FetchUserFinanceData extends FinanceEvent {
  final String userId;
  const FetchUserFinanceData(this.userId);

  @override
  List<Object> get props => [userId];
}

class FetchAdminFinanceData extends FinanceEvent {}

class SubmitPaymentRequested extends FinanceEvent {
  final String userId;
  final String kategoriId;
  final int amount;
  final int bulan;
  final int tahun;
  final String buktiPath;

  const SubmitPaymentRequested({
    required this.userId,
    required this.kategoriId,
    required this.amount,
    required this.bulan,
    required this.tahun,
    required this.buktiPath,
  });

  @override
  List<Object> get props => [userId, kategoriId, amount, bulan, tahun, buktiPath];
}

class UpdatePaymentStatusRequested extends FinanceEvent {
  final String paymentId;
  final String status;
  const UpdatePaymentStatusRequested(this.paymentId, this.status);

  @override
  List<Object> get props => [paymentId, status];
}

class AddExpenseRequested extends FinanceEvent {
  final String judul;
  final int nominal;
  final DateTime tanggal;

  const AddExpenseRequested({required this.judul, required this.nominal, required this.tanggal});

  @override
  List<Object> get props => [judul, nominal, tanggal];
}

class UpdateManualSaldoRequested extends FinanceEvent {
  final int newSaldo;
  const UpdateManualSaldoRequested(this.newSaldo);

  @override
  List<Object> get props => [newSaldo];
}

class AddBillCategoryRequested extends FinanceEvent {
  final String nama;
  final int nominal;
  const AddBillCategoryRequested(this.nama, this.nominal);

  @override
  List<Object> get props => [nama, nominal];
}

class ToggleBillStatusRequested extends FinanceEvent {
  final String id;
  final bool isActive;
  const ToggleBillStatusRequested(this.id, this.isActive);

  @override
  List<Object> get props => [id, isActive];
}
