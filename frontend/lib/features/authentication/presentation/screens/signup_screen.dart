import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/show_snackbar.dart';
import '../../../onboarding/presentation/screens/onboarding_screen.dart';
import '../../domain/validation/auth_validators.dart';
import '../bloc/auth_bloc.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  final AuthBloc? authBloc;
  const SignupScreen({super.key, this.authBloc});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  String? _nameError;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  AuthBloc? _safeAuthBloc(BuildContext context) {
    if (widget.authBloc != null) return widget.authBloc;
    try {
      return context.read<AuthBloc>();
    } catch (_) {
      return null;
    }
  }

  void _onSignUp() {
    final nameErr = AuthValidators.validateName(_nameController.text);
    final emailErr = AuthValidators.validateEmail(_emailController.text);
    final passwordErr =
        AuthValidators.validatePassword(_passwordController.text);

    setState(() {
      _nameError = nameErr;
      _emailError = emailErr;
      _passwordError = passwordErr;
    });

    if (nameErr == null && emailErr == null && passwordErr == null) {
      final bloc = _safeAuthBloc(context);
      if (bloc != null) {
        bloc.add(
          AuthSignUpSubmitted(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
          ),
        );
      }
    }
  }

  void _onGoogleSignIn() {
    final bloc = _safeAuthBloc(context);
    bloc?.add(const AuthGoogleSignInSubmitted());
  }

  @override
  Widget build(BuildContext context) {
    final bloc = _safeAuthBloc(context);
    if (bloc == null) {
      return _buildScaffold(false);
    }
    return BlocConsumer<AuthBloc, AuthState>(
      bloc: bloc,
      listener: (context, state) {
        if (state is Authenticated) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const OnboardingScreen(),
            ),
            (route) => false,
          );
        } else if (state is AuthFailure) {
          showSnackbar(context, state.message);
        }
      },
      builder: (context, state) {
        return _buildScaffold(state is AuthLoading);
      },
    );
  }

  Widget _buildScaffold(bool isLoading) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Brand Logo with minimal ambient gradient
              _buildBrandLogo(),
              const SizedBox(height: 20),
              // Title: "Create an Account"
              Text(
                'Create an Account',
                textAlign: TextAlign.center,
                style: AppTypography.headlineLg.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.02 * 28,
                ),
              ),
              const SizedBox(height: 6),
              // Subtitle: "Smart voice-first financial tracking"
              Text(
                'Smart voice-first financial tracking',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              // Social Auth: "Sign up with Google"
              _buildGoogleButton(isLoading),
              const SizedBox(height: 20),
              // Semantic Divider: "OR SIGN UP WITH EMAIL"
              _buildDivider(),
              const SizedBox(height: 20),
              // Credentials Form: Name, Email & Password
              _buildNameField(),
              const SizedBox(height: 16),
              _buildEmailField(),
              const SizedBox(height: 16),
              _buildPasswordField(),
              const SizedBox(height: 24),
              // Primary Action Button with Gradient & Glow
              _buildSignUpButton(isLoading),
              const SizedBox(height: 32),
              // Footer: "Already have an account? Sign In"
              _buildFooter(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Official Brand Logo with minimal ambient gradient and compact footprint
  Widget _buildBrandLogo() {
    return Center(
      child: SizedBox(
        width: 80,
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Minimal soft ambient aura - subtle and close to emblem
            Positioned(
              child: IgnorePointer(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(
                            0xFF2DD4BF,
                          ).withValues(alpha: 0.22), // Subtle teal
                          const Color(
                            0xFF10B981,
                          ).withValues(alpha: 0.12), // Subtle emerald
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.60, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Circular emblem with refined, minimal glow
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.22),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: const Color(0xFF2DD4BF).withValues(alpha: 0.14),
                    blurRadius: 28,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: _buildLogoBadge(),
            ),
          ],
        ),
      ),
    );
  }

  // The circular badge with gradient border and voice waveform
  Widget _buildLogoBadge() {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Color(0xFF2DD4BF), // Bright teal at top
            Color(0xFF10B981), // Emerald at bottom
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.all(1.5), // Gradient border thickness
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF0C131D), // Deep dark surface inside
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top glowing cyan dot
              Container(
                width: 3.5,
                height: 3.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF67E8F9),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF22D3EE).withValues(alpha: 0.8),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3.5),
              // 5-bar sound equalizer with cyan-to-emerald gradient
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildEqualizerBar(14),
                  const SizedBox(width: 3.5),
                  _buildEqualizerBar(22),
                  const SizedBox(width: 3.5),
                  _buildEqualizerBar(32),
                  const SizedBox(width: 3.5),
                  _buildEqualizerBar(22),
                  const SizedBox(width: 3.5),
                  _buildEqualizerBar(14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEqualizerBar(double height) {
    return Container(
      width: 4.5,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF38BDF8), // Cyan top
            Color(0xFF2DD4BF), // Teal mid
            Color(0xFF10B981), // Emerald bottom
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  // Sign up with Google Button
  Widget _buildGoogleButton(bool isLoading) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.50),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isLoading ? null : _onGoogleSignIn,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomPaint(
                size: const Size(20, 20),
                painter: const _GoogleLogoPainter(),
              ),
              const SizedBox(width: 12),
              Text(
                'Sign up with Google',
                style: AppTypography.titleMd.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Semantic Divider
  Widget _buildDivider() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: double.infinity,
          height: 1,
          color: AppColors.surfaceVariant, // #31353E
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: AppColors.surface, // #0F131C
          child: Text(
            'OR SIGN UP WITH EMAIL',
            style: AppTypography.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // Full Name Field matching Stitch tokens
  Widget _buildNameField() {
    final hasError = _nameError != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'Full Name',
            style: AppTypography.labelMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow.withValues(alpha: 0.80),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError
                  ? AppColors.error
                  : AppColors.outlineVariant.withValues(alpha: 0.40),
              width: hasError ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: TextField(
              controller: _nameController,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
              cursorColor: AppColors.primary,
              onChanged: (_) {
                if (_nameError != null) {
                  setState(() => _nameError = null);
                }
              },
              decoration: InputDecoration(
                hintText: 'Alex Morgan',
                hintStyle: AppTypography.bodyMd.copyWith(
                  color: AppColors.outline,
                ),
                prefixIcon: const Icon(
                  Icons.person_outline,
                  color: AppColors.outline,
                  size: 20,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              _nameError!,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Email Field matching Stitch tokens
  Widget _buildEmailField() {
    final hasError = _emailError != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'Email Address',
            style: AppTypography.labelMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow.withValues(alpha: 0.80),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError
                  ? AppColors.error
                  : AppColors.outlineVariant.withValues(alpha: 0.40),
              width: hasError ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
              cursorColor: AppColors.primary,
              onChanged: (_) {
                if (_emailError != null) {
                  setState(() => _emailError = null);
                }
              },
              decoration: InputDecoration(
                hintText: 'you@example.com',
                hintStyle: AppTypography.bodyMd.copyWith(
                  color: AppColors.outline,
                ),
                prefixIcon: const Icon(
                  Icons.alternate_email,
                  color: AppColors.outline,
                  size: 20,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              _emailError!,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Password Field matching Stitch tokens
  Widget _buildPasswordField() {
    final hasError = _passwordError != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'Password',
            style: AppTypography.labelMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow.withValues(alpha: 0.80),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError
                  ? AppColors.error
                  : AppColors.outlineVariant.withValues(alpha: 0.40),
              width: hasError ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
              cursorColor: AppColors.primary,
              onChanged: (_) {
                if (_passwordError != null) {
                  setState(() => _passwordError = null);
                }
              },
              decoration: InputDecoration(
                hintText: 'Create a password (min 8 chars, 1 number)',
                hintStyle: AppTypography.bodyMd.copyWith(
                  color: AppColors.outline,
                ),
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: AppColors.outline,
                  size: 20,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.outline,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              _passwordError!,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Primary Action Button with Gradient & Glow
  Widget _buildSignUpButton(bool isLoading) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF34D399), // emerald-400
            AppColors.primary, // #4EDEA3
            Color(0xFF2DD4BF), // teal-400
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4EDEA3).withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isLoading ? null : _onSignUp,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.onPrimary,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Create Account',
                        style: AppTypography.titleMd.copyWith(
                          color: AppColors.onPrimary, // #003824
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward,
                        color: AppColors.onPrimary, // #003824
                        size: 20,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // Footer: "Already have an account? Sign In"
  Widget _buildFooter() {
    return Row(
      spacing: 4,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        GestureDetector(
          onTap: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            }
          },
          child: Text(
            'Sign In',
            style: AppTypography.titleMd.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// Pixel-perfect Official Google 4-Color Logo Painter
class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    canvas.save();
    canvas.scale(w / 24.0, h / 24.0);

    // Blue Path (#4285F4)
    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    final bluePath = Path()
      ..moveTo(23.745, 12.27)
      ..cubicTo(23.745, 11.48, 23.68, 10.73, 23.55, 10.01)
      ..lineTo(12.0, 10.01)
      ..lineTo(12.0, 14.73)
      ..lineTo(18.59, 14.73)
      ..cubicTo(18.3, 16.27, 17.43, 17.58, 16.12, 18.45)
      ..lineTo(16.12, 21.56)
      ..lineTo(20.08, 21.56)
      ..cubicTo(22.4, 19.42, 23.745, 16.26, 23.745, 12.27)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // Green Path (#34A853)
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    final greenPath = Path()
      ..moveTo(12.0, 24.0)
      ..cubicTo(15.24, 24.0, 17.96, 22.92, 20.08, 20.97)
      ..lineTo(16.12, 17.86)
      ..cubicTo(15.03, 18.59, 13.63, 19.03, 12.0, 19.03)
      ..cubicTo(8.87, 19.03, 6.22, 16.92, 5.27, 14.07)
      ..lineTo(1.19, 14.07)
      ..lineTo(1.19, 17.23)
      ..cubicTo(3.21, 21.25, 7.28, 24.0, 12.0, 24.0)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // Yellow Path (#FBBC05)
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final yellowPath = Path()
      ..moveTo(5.27, 14.07)
      ..cubicTo(5.02, 13.33, 4.88, 12.54, 4.88, 11.72)
      ..cubicTo(4.88, 10.9, 5.02, 10.11, 5.27, 9.37)
      ..lineTo(5.27, 6.21)
      ..lineTo(1.19, 6.21)
      ..cubicTo(0.43, 7.73, 0.0, 9.68, 0.0, 11.72)
      ..cubicTo(0.0, 13.76, 0.43, 15.71, 1.19, 17.23)
      ..lineTo(5.27, 14.07)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // Red Path (#EA4335)
    final redPaint = Paint()..color = const Color(0xFFEA4335);
    final redPath = Path()
      ..moveTo(12.0, 4.75)
      ..cubicTo(13.77, 4.75, 15.35, 5.36, 16.6, 6.55)
      ..lineTo(20.02, 3.13)
      ..cubicTo(17.95, 1.19, 15.24, 0.0, 12.0, 0.0)
      ..cubicTo(7.28, 0.0, 3.21, 2.75, 1.19, 6.77)
      ..lineTo(5.27, 9.93)
      ..cubicTo(6.22, 7.08, 8.87, 4.75, 12.0, 4.75)
      ..close();
    canvas.drawPath(redPath, redPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
