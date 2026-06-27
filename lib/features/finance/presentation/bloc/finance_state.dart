import 'package:equatable/equatable.dart';
import '../../domain/entities/finance_entities.dart';

abstract class FinanceState extends Equatable {
  const FinanceState();
  
  @override
  List<Object?> get props => [];
}

class FinanceInitial extends FinanceState {}

class FinanceLoading extends FinanceState {}

class UserFinanceLoaded extends FinanceState {
  final List<BillEntity> activeBills;
  final List<PaymentEntity> paymentHistory;
  const UserFinanceLoaded({required this.activeBills, required this.paymentHistory});

  @override
  List<Object?> get props => [activeBills, paymentHistory];
}

class AdminFinanceLoaded extends FinanceState {
  final List<PaymentEntity> pendingPayments;
  final List<BillEntity> allCategories;
  final List<ExpenseEntity> allExpenses;
  const AdminFinanceLoaded({required this.pendingPayments, required this.allCategories, required this.allExpenses});

  @override
  List<Object?> get props => [pendingPayments, allCategories, allExpenses];
}

class FinanceActionSuccess extends FinanceState {
  final String message;
  const FinanceActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class FinanceFailure extends FinanceState {
  final String message;
  const FinanceFailure(this.message);

  @override
  List<Object?> get props => [message];
}
