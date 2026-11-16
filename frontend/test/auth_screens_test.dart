import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/authentication/presentation/screens/forgot_password_screen.dart';
import 'package:frontend/features/authentication/presentation/screens/login_screen.dart';
import 'package:frontend/features/authentication/presentation/screens/reset_password_screen.dart';
import 'package:frontend/features/authentication/presentation/screens/signup_screen.dart';
import 'package:frontend/features/onboarding/presentation/screens/onboarding_screen.dart';

void main() {
  testWidgets('LoginScreen renders all essential elements', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Simpex'), findsOneWidget);
    expect(find.text('Smart voice-first financial tracking'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('OR SIGN IN WITH EMAIL'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
  });

  testWidgets('SignupScreen renders all essential elements', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SignupScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create an Account'), findsOneWidget);
    expect(find.text('Smart voice-first financial tracking'), findsOneWidget);
    expect(find.text('Sign up with Google'), findsOneWidget);
    expect(find.text('OR SIGN UP WITH EMAIL'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('ForgotPasswordScreen renders all essential elements', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ForgotPasswordScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Forgot Password'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Send Code'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('ResetPasswordScreen renders 4-digit code and password inputs', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ResetPasswordScreen(email: 'user@example.com'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reset Password'), findsWidgets); // Title and button
    expect(find.textContaining('user@example.com'), findsOneWidget);
    expect(find.text('Verification Code'), findsOneWidget);
    expect(find.text('Resend Code'), findsOneWidget);
    expect(find.text('New Password'), findsOneWidget);
    expect(find.text('Confirm New Password'), findsOneWidget);
  });

  testWidgets('OnboardingScreen renders all profile setup fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Let's set up your profile"), findsOneWidget);
    expect(find.text('FIRST NAME'), findsOneWidget);
    expect(find.text('LAST NAME'), findsOneWidget);
    expect(find.text('PHONE NUMBER'), findsOneWidget);
    expect(find.text('PREFERRED BASE CURRENCY'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
