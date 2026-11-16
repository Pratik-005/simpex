import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/get_current_user_use_case.dart';
import '../../domain/usecases/google_sign_in_use_case.dart';
import '../../domain/usecases/login_use_case.dart';
import '../../domain/usecases/logout_use_case.dart';
import '../../domain/usecases/signup_use_case.dart';
import '../../domain/usecases/update_profile_use_case.dart';
import '../../../expenses/data/mock_expense_repository.dart';
import '../../../budget/data/repositories/budget_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;
  final SignUpUseCase _signUpUseCase;
  final GoogleSignInUseCase _googleSignInUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final UpdateProfileUseCase? _updateProfileUseCase;

  AuthBloc({
    required LoginUseCase loginUseCase,
    required SignUpUseCase signUpUseCase,
    required GoogleSignInUseCase googleSignInUseCase,
    required LogoutUseCase logoutUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    UpdateProfileUseCase? updateProfileUseCase,
  })  : _loginUseCase = loginUseCase,
        _signUpUseCase = signUpUseCase,
        _googleSignInUseCase = googleSignInUseCase,
        _logoutUseCase = logoutUseCase,
        _getCurrentUserUseCase = getCurrentUserUseCase,
        _updateProfileUseCase = updateProfileUseCase,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginSubmitted>(_onAuthLoginSubmitted);
    on<AuthSignUpSubmitted>(_onAuthSignUpSubmitted);
    on<AuthGoogleSignInSubmitted>(_onAuthGoogleSignInSubmitted);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthUpdateProfileSubmitted>(_onAuthUpdateProfileSubmitted);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final hasSession = await _getCurrentUserUseCase.hasSession();
    if (!hasSession) {
      emit(const Unauthenticated());
      return;
    }

    // Fast-path: immediately utilize cached user details if available
    final cachedUser = _getCurrentUserUseCase.getCachedUser();
    if (cachedUser != null) {
      emit(Authenticated(cachedUser));
    }

    // Background fresh profile verification
    final result = await _getCurrentUserUseCase(const NoParams());
    result.fold(
      (failure) {
        if (cachedUser == null) {
          emit(const Unauthenticated());
        }
      },
      (freshUser) => emit(Authenticated(freshUser)),
    );
  }

  Future<void> _onAuthLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Signing in...'));
    final result = await _loginUseCase(
      LoginParams(
        email: event.email,
        password: event.password,
      ),
    );

    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (user) {
        MockExpenseRepository.instance.fetchBackendExpenses();
        BudgetRepository.instance.fetchCurrentBudget();
        emit(Authenticated(user));
      },
    );
  }

  Future<void> _onAuthSignUpSubmitted(
    AuthSignUpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Creating your account...'));
    final result = await _signUpUseCase(
      SignUpParams(
        email: event.email,
        password: event.password,
        name: event.name,
        currency: event.currency,
        locale: event.locale,
      ),
    );

    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (user) {
        MockExpenseRepository.instance.fetchBackendExpenses();
        BudgetRepository.instance.fetchCurrentBudget();
        emit(Authenticated(user));
      },
    );
  }

  Future<void> _onAuthGoogleSignInSubmitted(
    AuthGoogleSignInSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Connecting with Google...'));
    final result = await _googleSignInUseCase(
      GoogleSignInParams(
        explicitIdToken: event.explicitIdToken,
      ),
    );

    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (user) {
        MockExpenseRepository.instance.fetchBackendExpenses();
        BudgetRepository.instance.fetchCurrentBudget();
        emit(Authenticated(user));
      },
    );
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Logging out...'));
    MockExpenseRepository.instance.clear();
    BudgetRepository.instance.clear();
    await _logoutUseCase(const NoParams());
    emit(const Unauthenticated());
  }

  Future<void> _onAuthUpdateProfileSubmitted(
    AuthUpdateProfileSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    if (_updateProfileUseCase == null) return;
    emit(const AuthLoading(message: 'Saving your details...'));
    final result = await _updateProfileUseCase(
      UpdateProfileParams(
        name: event.name,
        phone: event.phone,
        currency: event.currency,
        locale: event.locale,
        avatarUrl: event.avatarUrl,
      ),
    );

    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }
}
