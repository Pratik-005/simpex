import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/constants/app_constants.dart';
import '../core/injection/init_dependencies.dart';
import '../features/authentication/presentation/bloc/auth_bloc.dart';
import '../features/authentication/presentation/screens/forgot_password_screen.dart';
import '../features/authentication/presentation/screens/login_screen.dart';
import '../features/authentication/presentation/screens/reset_password_screen.dart';
import '../features/authentication/presentation/screens/signup_screen.dart';
import '../features/categories/presentation/screens/categories_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import 'app_root.dart';
import 'main_shell_page.dart';
import 'theme/app_theme.dart';

class MyApp extends StatelessWidget {
  final AuthBloc? authBloc;
  final Widget? home;

  const MyApp({
    super.key,
    this.authBloc,
    this.home,
  });

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      debugShowCheckedModeBanner: false,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      title: AppConstants.appName,
      theme: AppTheme.darkTheme,
      builder: (context, child) {
        final MediaQueryData data = MediaQuery.of(context);
        return MediaQuery(
          data: data.copyWith(textScaler: const TextScaler.linear(1.0)),
          child: SafeArea(
            bottom: true,
            top: false,
            left: true,
            right: true,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: home ?? const AppRoot(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/dashboard': (context) => const MainShellPage(),
        '/categories': (context) => const CategoriesScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
      },
    );

    if (authBloc != null) {
      return BlocProvider<AuthBloc>.value(
        value: authBloc!,
        child: app,
      );
    }

    if (sl.isRegistered<AuthBloc>()) {
      return MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                sl<AuthBloc>()..add(const AuthCheckRequested()),
          ),
        ],
        child: app,
      );
    }

    return app;
  }
}

typedef SimpexApp = MyApp;
