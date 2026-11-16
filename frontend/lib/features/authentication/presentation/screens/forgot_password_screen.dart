import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onSendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _isLoading = false);

    // Redirect to reset password page with email
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResetPasswordScreen(email: email),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              // Brand Logo with minimal ambient gradient
              _buildBrandLogo(),
              const SizedBox(height: 20),
              // Title: "Forgot Password"
              Text(
                'Forgot Password',
                textAlign: TextAlign.center,
                style: AppTypography.headlineLg.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.02 * 28,
                ),
              ),
              const SizedBox(height: 6),
              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Enter your email address and we will send a 4-digit code to reset your password.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 36),
              // Email Field
              _buildEmailField(),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      _errorMessage!,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Primary Action Button: Send Code
              _buildSendCodeButton(),
              const SizedBox(height: 32),
              // Footer: Back to Sign In
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

  // Email Field matching login & signup tokens
  Widget _buildEmailField() {
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
              color: _errorMessage != null
                  ? AppColors.error
                  : AppColors.outlineVariant.withValues(alpha: 0.40),
              width: 1,
            ),
          ),
          child: Center(
            child: TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
              cursorColor: AppColors.primary,
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
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() => _errorMessage = null);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  // Primary Action Button: Send Verification Code
  Widget _buildSendCodeButton() {
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
          onTap: _isLoading ? null : _onSendCode,
          child: Center(
            child: _isLoading
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
                        'Send Code',
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

  // Footer: Back to Sign In
  Widget _buildFooter() {
    return Row(
      spacing: 4,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Remember your password? ',
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
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
