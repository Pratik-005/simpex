import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/injection/init_dependencies.dart';
import '../core/storage/auth_storage.dart';
import '../core/utils/show_snackbar.dart';
import '../core/widgets/loader.dart';
import '../features/authentication/presentation/bloc/auth_bloc.dart';
import '../features/authentication/presentation/screens/login_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import 'main_shell_page.dart';
import 'theme/app_colors.dart';

class AppRoot extends StatelessWidget {
  final AuthBloc? authBloc;
  const AppRoot({super.key, this.authBloc});

  AuthBloc? _resolveAuthBloc(BuildContext context) {
    if (authBloc != null) return authBloc;
    try {
      return context.read<AuthBloc>();
    } catch (_) {
      if (sl.isRegistered<AuthBloc>()) {
        return sl<AuthBloc>();
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = _resolveAuthBloc(context);

    if (bloc == null) {
      return const LoginScreen();
    }

    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          bloc: bloc,
          listener: (context, state) {
            if (state is AuthFailure) {
              showSnackbar(context, state.message);
            }
          },
        ),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        bloc: bloc,
        builder: (context, authState) {
          if (authState is Authenticated) {
            final authStorage =
                sl.isRegistered<AuthStorage>() ? sl<AuthStorage>() : null;
            final isCompleted = authState.user.onboardingCompleted ||
                (authStorage?.hasCompletedOnboarding(authState.user.id) ?? false);
            if (!isCompleted) {
              return const OnboardingScreen();
            }
            return const MainShellPage();
          }

          if (authState is AuthInitial) {
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(child: Loader()),
            );
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
