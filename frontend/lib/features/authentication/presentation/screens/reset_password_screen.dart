import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? email;

  const ResetPasswordScreen({super.key, this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _digit1Controller = TextEditingController();
  final _digit2Controller = TextEditingController();
  final _digit3Controller = TextEditingController();
  final _digit4Controller = TextEditingController();

  final _focus1 = FocusNode();
  final _focus2 = FocusNode();
  final _focus3 = FocusNode();
  final _focus4 = FocusNode();

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _digit1Controller.dispose();
    _digit2Controller.dispose();
    _digit3Controller.dispose();
    _digit4Controller.dispose();
    _focus1.dispose();
    _focus2.dispose();
    _focus3.dispose();
    _focus4.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String get _code =>
      '${_digit1Controller.text}${_digit2Controller.text}${_digit3Controller.text}${_digit4Controller.text}';

  void _onResetPassword() async {
    final code = _code;
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (code.length < 4) {
      setState(() => _errorMessage = 'Please enter the complete 4-digit code');
      return;
    }

    if (password.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters');
      return;
    }

    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceContainer,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.primary, width: 1),
        ),
        content: Text(
          'Password reset successfully! Please sign in.',
          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
        ),
      ),
    );

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _onResendCode() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceContainer,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        content: Text(
          'New 4-digit code sent to ${widget.email ?? "your email"}',
          style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayEmail = widget.email ?? 'your email';

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
              // Title: "Reset Password"
              Text(
                'Reset Password',
                textAlign: TextAlign.center,
                style: AppTypography.headlineLg.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.02 * 28,
                ),
              ),
              const SizedBox(height: 6),
              // Subtitle with user email
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Enter the 4-digit verification code sent to\n$displayEmail',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // 4-Digit Code Input Section
              _buildCodeInputSection(),
              const SizedBox(height: 16),
              // Resend code row
              _buildResendRow(),
              const SizedBox(height: 24),
              // New Password Field
              _buildPasswordField(),
              const SizedBox(height: 16),
              // Confirm New Password Field
              _buildConfirmPasswordField(),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
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
              // Primary Action Button
              _buildResetButton(),
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

  // 4-Digit Verification Code Boxes
  Widget _buildCodeInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Verification Code',
            style: AppTypography.labelMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildDigitBox(_digit1Controller, _focus1, _focus2, null),
            _buildDigitBox(_digit2Controller, _focus2, _focus3, _focus1),
            _buildDigitBox(_digit3Controller, _focus3, _focus4, _focus2),
            _buildDigitBox(_digit4Controller, _focus4, null, _focus3),
          ],
        ),
      ],
    );
  }

  Widget _buildDigitBox(
    TextEditingController controller,
    FocusNode currentFocus,
    FocusNode? nextFocus,
    FocusNode? prevFocus,
  ) {
    final hasValue = controller.text.isNotEmpty;
    final isFocused = currentFocus.hasFocus;

    return Container(
      width: 68,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isFocused || hasValue)
              ? AppColors.primary
              : AppColors.outlineVariant.withValues(alpha: 0.40),
          width: (isFocused || hasValue) ? 1.5 : 1.0,
        ),
        boxShadow: (isFocused || hasValue)
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.20),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.backspace &&
                controller.text.isEmpty &&
                prevFocus != null) {
              prevFocus.requestFocus();
            }
          },
          child: TextField(
            controller: controller,
            focusNode: currentFocus,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            cursorColor: AppColors.primary,
            inputFormatters: [
              LengthLimitingTextInputFormatter(1),
              FilteringTextInputFormatter.digitsOnly,
            ],
            style: AppTypography.headlineSm.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              setState(() {
                if (_errorMessage != null) _errorMessage = null;
              });
              if (value.isNotEmpty) {
                if (nextFocus != null) {
                  nextFocus.requestFocus();
                } else {
                  currentFocus.unfocus();
                }
              }
            },
          ),
        ),
      ),
    );
  }

  // Resend code row
  Widget _buildResendRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive code? ",
          style: AppTypography.bodySm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        GestureDetector(
          onTap: _onResendCode,
          child: Text(
            'Resend Code',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // New Password Field
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'New Password',
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
              color: AppColors.outlineVariant.withValues(alpha: 0.40),
              width: 1,
            ),
          ),
          child: Center(
            child: TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: 'Enter new password',
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

  // Confirm New Password Field
  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'Confirm New Password',
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
              color: AppColors.outlineVariant.withValues(alpha: 0.40),
              width: 1,
            ),
          ),
          child: Center(
            child: TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: 'Re-enter new password',
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
                    _obscureConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: AppColors.outline,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    );
                  },
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

  // Primary Action Button: Reset Password
  Widget _buildResetButton() {
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
          onTap: _isLoading ? null : _onResetPassword,
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
                        'Reset Password',
                        style: AppTypography.titleMd.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward,
                        color: AppColors.onPrimary,
                        size: 20,
                      ),
                    ],
                  ),
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
                          const Color(0xFF2DD4BF).withValues(alpha: 0.22),
                          const Color(0xFF10B981).withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.60, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),
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

  Widget _buildLogoBadge() {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF2DD4BF), Color(0xFF10B981)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.all(1.5),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF0C131D),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
          colors: [Color(0xFF38BDF8), Color(0xFF2DD4BF), Color(0xFF10B981)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
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
          onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
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
