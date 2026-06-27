import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import '../../domain/repositories/finance_repository.dart';
import 'finance_event.dart';
import 'finance_state.dart';

class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {
  final FinanceRepository repository;

  FinanceBloc({required this.repository}) : super(FinanceInitial()) {
    on<FetchUserFinanceData>(_onFetchUserFinanceData);
    on<FetchAdminFinanceData>(_onFetchAdminFinanceData);
    on<SubmitPaymentRequested>(_onSubmitPaymentRequested);
    on<UpdatePaymentStatusRequested>(_onUpdatePaymentStatusRequested);
    on<AddExpenseRequested>(_onAddExpenseRequested);
    on<UpdateManualSaldoRequested>(_onUpdateManualSaldoRequested);
    on<AddBillCategoryRequested>(_onAddBillCategoryRequested);
    on<ToggleBillStatusRequested>(_onToggleBillStatusRequested);
  }

  Future<void> _onFetchUserFinanceData(FetchUserFinanceData event, Emitter<FinanceState> emit) async {
    emit(FinanceLoading());
    await emit.forEach(
      Rx.combineLatest2(
        repository.watchActiveBills(event.userId),
        repository.watchUserPayments(event.userId),
        (bills, payments) => UserFinanceLoaded(activeBills: bills, paymentHistory: payments),
      ),
      onData: (state) => state,
      onError: (error, stackTrace) => FinanceFailure(error.toString()),
    );
  }

  Future<void> _onFetchAdminFinanceData(FetchAdminFinanceData event, Emitter<FinanceState> emit) async {
    emit(FinanceLoading());
    await emit.forEach(
      Rx.combineLatest3(
        repository.watchPendingPayments(),
        repository.watchActiveBills(''), 
        repository.watchExpenses(),
        (pending, cats, expenses) => AdminFinanceLoaded(pendingPayments: pending, allCategories: cats, allExpenses: expenses),
      ),
      onData: (state) => state,
      onError: (error, stackTrace) => FinanceFailure(error.toString()),
    );
  }

  Future<void> _onSubmitPaymentRequested(SubmitPaymentRequested event, Emitter<FinanceState> emit) async {
    emit(FinanceLoading());
    final result = await repository.submitPayment(
      userId: event.userId,
      kategoriId: event.kategoriId,
      amount: event.amount,
      bulan: event.bulan,
      tahun: event.tahun,
      buktiPath: event.buktiPath,
    );

    result.fold(
      (failure) => emit(FinanceFailure(failure.message)),
      (_) => emit(const FinanceActionSuccess('Bukti pembayaran berhasil dikirim!')),
    );
  }

  Future<void> _onUpdatePaymentStatusRequested(UpdatePaymentStatusRequested event, Emitter<FinanceState> emit) async {
    final result = await repository.updatePaymentStatus(event.paymentId, event.status);
    result.fold(
      (failure) => emit(FinanceFailure(failure.message)),
      (_) => emit(FinanceActionSuccess(event.status == 'approved' ? 'Pembayaran disetujui' : 'Pembayaran ditolak')),
    );
  }

  Future<void> _onAddExpenseRequested(AddExpenseRequested event, Emitter<FinanceState> emit) async {
    emit(FinanceLoading());
    final result = await repository.addExpense(
      judul: event.judul,
      nominal: event.nominal,
      tanggal: event.tanggal,
    );

    result.fold(
      (failure) => emit(FinanceFailure(failure.message)),
      (_) => emit(const FinanceActionSuccess('Pengeluaran berhasil dicatat')),
    );
  }

  Future<void> _onUpdateManualSaldoRequested(UpdateManualSaldoRequested event, Emitter<FinanceState> emit) async {
    emit(FinanceLoading());
    final result = await repository.updateManualSaldo(event.newSaldo);
    result.fold(
      (failure) => emit(FinanceFailure(failure.message)),
      (_) => emit(const FinanceActionSuccess('Saldo Kas diperbarui!')),
    );
  }

  Future<void> _onAddBillCategoryRequested(AddBillCategoryRequested event, Emitter<FinanceState> emit) async {
    emit(FinanceLoading());
    final result = await repository.addBillCategory(nama: event.nama, nominal: event.nominal);
    result.fold(
      (failure) => emit(FinanceFailure(failure.message)),
      (_) => emit(const FinanceActionSuccess('Kategori iuran baru berhasil ditambahkan')),
    );
  }

  Future<void> _onToggleBillStatusRequested(ToggleBillStatusRequested event, Emitter<FinanceState> emit) async {
    final result = await repository.toggleBillStatus(event.id, event.isActive);
    result.fold(
      (failure) => emit(FinanceFailure(failure.message)),
      (_) => emit(const FinanceActionSuccess('Status iuran diperbarui')),
    );
  }
}
