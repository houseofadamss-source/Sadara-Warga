import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/umkm/data/datasources/umkm_remote_data_source.dart';
import 'features/umkm/data/repositories/umkm_repository_impl.dart';
import 'features/umkm/domain/repositories/umkm_repository.dart';
import 'features/umkm/domain/usecases/register_umkm_usecase.dart';
import 'features/umkm/domain/usecases/get_featured_umkm.dart';
import 'features/umkm/presentation/bloc/umkm_bloc.dart';
import 'features/sos/data/datasources/emergency_remote_data_source.dart';
import 'features/sos/data/repositories/emergency_repository_impl.dart';
import 'features/sos/domain/repositories/emergency_repository.dart';
import 'features/sos/domain/usecases/watch_active_contacts.dart';
import 'features/sos/presentation/bloc/sos_bloc.dart';
import 'features/announcements/data/datasources/announcement_remote_data_source.dart';
import 'features/announcements/data/repositories/announcement_repository_impl.dart';
import 'features/announcements/domain/repositories/announcement_repository.dart';
import 'features/announcements/presentation/bloc/announcement_bloc.dart';
import 'features/events/data/datasources/event_remote_data_source.dart';
import 'features/events/data/repositories/event_repository_impl.dart';
import 'features/events/domain/repositories/event_repository.dart';
import 'features/events/presentation/bloc/events_bloc.dart';
import 'features/finance/data/datasources/finance_remote_data_source.dart';
import 'features/finance/data/repositories/finance_repository_impl.dart';
import 'features/finance/domain/repositories/finance_repository.dart';
import 'features/finance/presentation/bloc/finance_bloc.dart';
import 'features/surat/data/datasources/surat_remote_data_source.dart';
import 'features/surat/data/repositories/surat_repository_impl.dart';
import 'features/surat/domain/repositories/surat_repository.dart';
import 'features/surat/presentation/bloc/surat_bloc.dart';
import 'features/reports/data/datasources/report_remote_data_source.dart';
import 'features/reports/data/repositories/report_repository_impl.dart';
import 'features/reports/domain/repositories/report_repository.dart';
import 'features/reports/presentation/bloc/report_bloc.dart';
import 'features/profile/data/datasources/version_remote_data_source.dart';
import 'features/profile/data/repositories/version_repository_impl.dart';
import 'features/profile/domain/repositories/version_repository.dart';
import 'package:http/http.dart' as http;
import 'features/citizen_management/data/datasources/citizen_remote_data_source.dart';
import 'features/citizen_management/data/repositories/citizen_repository_impl.dart';
import 'features/citizen_management/domain/repositories/citizen_repository.dart';
import 'features/citizen_management/presentation/bloc/citizen_bloc.dart';
import 'services/osm_api_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Auth
  sl.registerFactory(() => AuthBloc(
    loginUseCase: sl(),
    registerUseCase: sl(),
  ));
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );

  //! Features - UMKM
  sl.registerFactory(() => UmkmBloc(
    repository: sl(),
    registerUseCase: sl(),
  ));
  sl.registerLazySingleton(() => RegisterUmkmUseCase(sl()));
  sl.registerLazySingleton(() => GetFeaturedUmkm(sl()));
  sl.registerLazySingleton<UmkmRepository>(
    () => UmkmRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<UmkmRemoteDataSource>(
    () => UmkmRemoteDataSourceImpl(client: sl(), osmApi: sl()),
  );

  //! Features - SOS/Emergency
  sl.registerFactory(() => SosBloc(repository: sl()));
  sl.registerLazySingleton(() => WatchActiveContacts(sl()));
  sl.registerLazySingleton<EmergencyRepository>(
    () => EmergencyRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<EmergencyRemoteDataSource>(
    () => EmergencyRemoteDataSourceImpl(sl()),
  );

  //! Features - Announcements
  sl.registerFactory(() => AnnouncementBloc(repository: sl()));
  sl.registerLazySingleton<AnnouncementRepository>(
    () => AnnouncementRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<AnnouncementRemoteDataSource>(
    () => AnnouncementRemoteDataSourceImpl(sl()),
  );

  //! Features - Events
  sl.registerFactory(() => EventsBloc(repository: sl()));
  sl.registerLazySingleton<EventRepository>(
    () => EventRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<EventRemoteDataSource>(
    () => EventRemoteDataSourceImpl(sl()),
  );

  //! Features - Finance
  sl.registerFactory(() => FinanceBloc(repository: sl()));
  sl.registerLazySingleton<FinanceRepository>(
    () => FinanceRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<FinanceRemoteDataSource>(
    () => FinanceRemoteDataSourceImpl(sl()),
  );

  //! Features - Surat
  sl.registerFactory(() => SuratBloc(repository: sl()));
  sl.registerLazySingleton<SuratRepository>(
    () => SuratRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<SuratRemoteDataSource>(
    () => SuratRemoteDataSourceImpl(sl()),
  );

  //! Features - Reports
  sl.registerFactory(() => ReportBloc(repository: sl()));
  sl.registerLazySingleton<ReportRepository>(
    () => ReportRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<ReportRemoteDataSource>(
    () => ReportRemoteDataSourceImpl(sl()),
  );

  //! Features - Citizen Management
  sl.registerFactory(() => CitizenBloc(repository: sl()));
  sl.registerLazySingleton<CitizenRepository>(
    () => CitizenRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<CitizenRemoteDataSource>(
    () => CitizenRemoteDataSourceImpl(sl()),
  );

  //! Versioning/Changelog
  sl.registerLazySingleton<VersionRepository>(
    () => VersionRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<VersionRemoteDataSource>(
    () => VersionRemoteDataSourceImpl(client: sl()),
  );

  //! External & Services
  sl.registerLazySingleton(() => Supabase.instance.client);
  sl.registerLazySingleton(() => OsmApiService());
  sl.registerLazySingleton(() => http.Client());
}
