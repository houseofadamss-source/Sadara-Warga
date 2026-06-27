import 'package:equatable/equatable.dart';

abstract class ReportState extends Equatable {
  const ReportState();
  
  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState {}

class ReportLoading extends ReportState {}

class ReportActionSuccess extends ReportState {
  final String message;
  const ReportActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class ReportFailure extends ReportState {
  final String message;
  const ReportFailure(this.message);

  @override
  List<Object?> get props => [message];
}
