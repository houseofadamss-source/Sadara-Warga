import 'package:equatable/equatable.dart';
import '../../domain/entities/report_entity.dart';

abstract class ReportEvent extends Equatable {
  const ReportEvent();

  @override
  List<Object> get props => [];
}

class SubmitReportRequested extends ReportEvent {
  final ReportEntity report;
  final String? localImagePath;
  const SubmitReportRequested(this.report, this.localImagePath);

  @override
  List<Object> get props => [report, if (localImagePath != null) localImagePath!];
}

class UpdateReportStatusRequested extends ReportEvent {
  final String id;
  final String newStatus;
  const UpdateReportStatusRequested(this.id, this.newStatus);

  @override
  List<Object> get props => [id, newStatus];
}
