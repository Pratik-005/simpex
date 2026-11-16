import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/authentication/data/datasources/auth_local_data_source.dart';
import '../../features/authentication/data/datasources/auth_remote_data_source.dart';
import '../../features/authentication/data/repositories/auth_repository_impl.dart';
import '../../features/authentication/domain/repositories/auth_repository.dart';
import '../../features/authentication/domain/usecases/get_current_user_use_case.dart';
import '../../features/authentication/domain/usecases/google_sign_in_use_case.dart';
import '../../features/authentication/domain/usecases/login_use_case.dart';
import '../../features/authentication/domain/usecases/logout_use_case.dart';
import '../../features/authentication/domain/usecases/signup_use_case.dart';
import '../../features/authentication/domain/usecases/update_profile_use_case.dart';
import '../../features/authentication/presentation/bloc/auth_bloc.dart';
import '../../features/categories/data/datasources/category_local_data_source.dart';
import '../../features/categories/data/datasources/category_remote_data_source.dart';
import '../../features/categories/data/repositories/category_repository.dart';
import '../../features/expenses/data/datasources/expense_local_data_source.dart';
import '../../features/expenses/data/datasources/expense_remote_data_source.dart';
import '../../features/expenses/data/mock_expense_repository.dart';
import '../../features/budget/data/datasources/budget_local_data_source.dart';
import '../../features/budget/data/datasources/budget_remote_data_source.dart';
import '../../features/budget/data/repositories/budget_repository.dart';
import '../../features/sync/data/datasources/sync_queue_local_data_source.dart';
import '../../features/sync/domain/services/sync_engine.dart';
import '../database/hive_service.dart';
import '../network/api_client.dart';
import '../network/connectivity_service.dart';
import '../storage/auth_storage.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);

  // Initialize Hive Offline Storage
  final hiveService = HiveService();
  await hiveService.init();
  sl.registerSingleton<HiveService>(hiveService);

  // Register Local Data Sources
  sl
    ..registerLazySingleton<SyncQueueLocalDataSource>(
      () => SyncQueueLocalDataSourceImpl(hiveService: sl<HiveService>()),
    )
    ..registerLazySingleton<ExpenseLocalDataSource>(
      () => ExpenseLocalDataSourceImpl(hiveService: sl<HiveService>()),
    )
    ..registerLazySingleton<CategoryLocalDataSource>(
      () => CategoryLocalDataSourceImpl(hiveService: sl<HiveService>()),
    )
    ..registerLazySingleton<BudgetLocalDataSource>(
      () => BudgetLocalDataSourceImpl(hiveService: sl<HiveService>()),
    );

  sl
    ..registerLazySingleton<Logger>(() => Logger())
    ..registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage(
        aOptions: AndroidOptions(resetOnError: true),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      ),
    )
    ..registerLazySingleton<AuthStorage>(
      () => AuthStorage(
        secureStorage: sl<FlutterSecureStorage>(),
        prefs: sl<SharedPreferences>(),
      ),
    )
    ..registerLazySingleton<ApiClient>(
      () => ApiClient(
        authStorage: sl<AuthStorage>(),
      ),
    )
    ..registerLazySingleton<Dio>(() => sl<ApiClient>().dio)
    ..registerLazySingleton<CategoryRemoteDataSource>(
      () => CategoryRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
    )
    ..registerLazySingleton<CategoryRepository>(
      () => CategoryRepository.instance,
    )
    ..registerLazySingleton<ExpenseRemoteDataSource>(
      () => ExpenseRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
    )
    ..registerLazySingleton<MockExpenseRepository>(
      () => MockExpenseRepository.instance,
    )
    ..registerLazySingleton<BudgetRemoteDataSource>(
      () => BudgetRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
    )
    ..registerLazySingleton<BudgetRepository>(
      () => BudgetRepository.instance,
    )
    ..registerLazySingleton<SyncEngine>(
      () => SyncEngine(
        syncQueueLocalDataSource: sl<SyncQueueLocalDataSource>(),
        expenseLocalDataSource: sl<ExpenseLocalDataSource>(),
        apiClient: sl<ApiClient>(),
      ),
    );

  // Connectivity & Sync Listener
  final connectivityService = ConnectivityService(
    onConnectionRestored: () {
      if (sl.isRegistered<SyncEngine>()) {
        sl<SyncEngine>().sync();
      }
    },
  );
  await connectivityService.init();
  sl.registerSingleton<ConnectivityService>(connectivityService);

  // Initialize cached states from local storage
  CategoryRepository.instance.initFromCache();
  BudgetRepository.instance.initFromCache();
  MockExpenseRepository.instance.initFromLocalStorage();

  // Trigger sync in background if there are pending operations
  sl<SyncEngine>().sync();

  // Features
  authInit();
}

void authInit() {
  sl
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(
        apiClient: sl<ApiClient>(),
        logger: sl<Logger>(),
      ),
    )
    ..registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(
        authStorage: sl<AuthStorage>(),
        logger: sl<Logger>(),
      ),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        remoteDataSource: sl<AuthRemoteDataSource>(),
        localDataSource: sl<AuthLocalDataSource>(),
        logger: sl<Logger>(),
      ),
    )
    ..registerLazySingleton(
      () => LoginUseCase(repository: sl<AuthRepository>()),
    )
    ..registerLazySingleton(
      () => SignUpUseCase(repository: sl<AuthRepository>()),
    )
    ..registerLazySingleton(
      () => GoogleSignInUseCase(repository: sl<AuthRepository>()),
    )
    ..registerLazySingleton(
      () => LogoutUseCase(repository: sl<AuthRepository>()),
    )
    ..registerLazySingleton(
      () => GetCurrentUserUseCase(repository: sl<AuthRepository>()),
    )
    ..registerLazySingleton(
      () => UpdateProfileUseCase(repository: sl<AuthRepository>()),
    )
    ..registerFactory(
      () => AuthBloc(
        loginUseCase: sl<LoginUseCase>(),
        signUpUseCase: sl<SignUpUseCase>(),
        googleSignInUseCase: sl<GoogleSignInUseCase>(),
        logoutUseCase: sl<LogoutUseCase>(),
        getCurrentUserUseCase: sl<GetCurrentUserUseCase>(),
        updateProfileUseCase: sl<UpdateProfileUseCase>(),
      ),
    );
}
