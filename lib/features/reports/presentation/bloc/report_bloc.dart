import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/report_repository.dart';
import 'report_event.dart';
import 'report_state.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final ReportRepository repository;

  ReportBloc({required this.repository}) : super(ReportInitial()) {
    on<SubmitReportRequested>(_onSubmitReportRequested);
    on<UpdateReportStatusRequested>(_onUpdateReportStatusRequested);
  }

  Future<void> _onSubmitReportRequested(SubmitReportRequested event, Emitter<ReportState> emit) async {
    emit(ReportLoading());
    final result = await repository.submitReport(report: event.report, localImagePath: event.localImagePath);
    result.fold(
      (failure) => emit(ReportFailure(failure.message)),
      (_) => emit(const ReportActionSuccess('Laporan berhasil dikirim!')),
    );
  }

  Future<void> _onUpdateReportStatusRequested(UpdateReportStatusRequested event, Emitter<ReportState> emit) async {
    emit(ReportLoading());
    final result = await repository.updateReportStatus(event.id, event.newStatus);
    result.fold(
      (failure) => emit(ReportFailure(failure.message)),
      (_) => emit(const ReportActionSuccess('Status laporan berhasil diperbarui')),
    );
  }
}
