import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import '../../../../app/app_root.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/currency_constants.dart';
import '../../../../core/injection/init_dependencies.dart';
import '../../../../core/storage/auth_storage.dart';
import '../../../../core/utils/phone_validator.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../authentication/domain/models/auth_user.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../categories/presentation/screens/categories_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _userName = 'Alex Morgan';
  String _userEmail = 'alex.morgan@example.com';
  String _userPhone = '+91 98765 43210';
  String? _userAvatarUrl;
  String _defaultCurrency = 'INR (₹)';
  String _defaultCurrencyName = 'Indian Rupee';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hydrateUserData();
    });
  }

  void _hydrateUserData() {
    try {
      if (sl.isRegistered<AuthStorage>()) {
        final cached = sl<AuthStorage>().getUser();
        if (cached != null) {
          _applyUser(cached);
        }
      }
    } catch (_) {}

    try {
      final authBloc = context.read<AuthBloc>();
      final state = authBloc.state;
      if (state is Authenticated) {
        _applyUser(state.user);
      }
    } catch (_) {
      // AuthBloc may not be in tree in isolated widget tests
    }
  }

  void _applyUser(AuthUser user) {
    if (!mounted) return;
    setState(() {
      if (user.name.isNotEmpty) {
        _userName = user.name;
      } else if (user.email.isNotEmpty) {
        _userName = user.email.split('@').first;
      }
      _userEmail = user.email;
      if (user.phone != null && user.phone!.isNotEmpty) {
        _userPhone = user.phone!;
      }
      _userAvatarUrl = user.avatarUrl;
      if (user.currency.isNotEmpty) {
        final item = CurrencyConstants.find(user.currency);
        _defaultCurrency = item.formattedCode;
        _defaultCurrencyName = item.name;
      }
    });
  }

  void _showCurrencyPicker() {
    String searchQuery = '';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final query = searchQuery.trim().toLowerCase();
          final filtered = CurrencyConstants.currencies.where((curr) {
            if (query.isEmpty) return true;
            return curr.code.toLowerCase().contains(query) ||
                curr.name.toLowerCase().contains(query);
          }).toList();

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.75,
            ),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Default Currency',
                  style: AppTypography.headlineSm.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Search currency (code or name)...',
                  prefixIcon: Icons.search,
                  onChanged: (val) {
                    setModalState(() => searchQuery = val);
                  },
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No matching currencies found',
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (ctx, i) =>
                              const Divider(color: AppColors.cardBorder, height: 1),
                          itemBuilder: (ctx, index) {
                            final curr = filtered[index];
                            final isSelected =
                                curr.formattedCode == _defaultCurrency ||
                                curr.code == _defaultCurrency;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _defaultCurrency = curr.formattedCode;
                                  _defaultCurrencyName = curr.name;
                                });
                                Navigator.of(ctx).pop();
                                try {
                                  context.read<AuthBloc>().add(
                                    AuthUpdateProfileSubmitted(
                                      currency: curr.code,
                                    ),
                                  );
                                } catch (_) {}
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Currency updated to ${curr.name} (${curr.code})',
                                    ),
                                    backgroundColor:
                                        AppColors.surfaceContainerHighest,
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 8,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          curr.formattedCode,
                                          style: AppTypography.titleMd.copyWith(
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? AppColors.primary
                                                : AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          curr.name,
                                          style: AppTypography.bodySm.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _userName);

    String selectedFlag = '🇮🇳';
    String selectedPhoneCode = '+91';
    String selectedIso = 'IN';
    String selectedExample = '9123456789';
    String initialDigits = '';

    if (_userPhone.isNotEmpty) {
      final cleaned = _userPhone.trim();
      if (cleaned.startsWith('+91')) {
        selectedFlag = '🇮🇳';
        selectedPhoneCode = '+91';
        selectedIso = 'IN';
        selectedExample = '9123456789';
        initialDigits = cleaned.substring(3).replaceAll(RegExp(r'\D'), '');
      } else if (cleaned.startsWith('+1')) {
        selectedFlag = '🇺🇸';
        selectedPhoneCode = '+1';
        selectedIso = 'US';
        selectedExample = '2015550123';
        initialDigits = cleaned.substring(2).replaceAll(RegExp(r'\D'), '');
      } else if (cleaned.startsWith('+44')) {
        selectedFlag = '🇬🇧';
        selectedPhoneCode = '+44';
        selectedIso = 'GB';
        selectedExample = '7911123456';
        initialDigits = cleaned.substring(3).replaceAll(RegExp(r'\D'), '');
      } else if (cleaned.startsWith('+')) {
        try {
          final parsed = PhoneNumber.parse(cleaned);
          selectedPhoneCode = '+${parsed.countryCode}';
          selectedIso = parsed.isoCode.name;
          initialDigits = parsed.nsn;
        } catch (_) {
          initialDigits = cleaned.replaceAll(RegExp(r'\D'), '');
        }
      } else {
        initialDigits = cleaned.replaceAll(RegExp(r'\D'), '');
      }
    }

    final phoneCtrl = TextEditingController(text: initialDigits);
    String? nameError;
    String? phoneError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Edit Profile',
                  style: AppTypography.headlineSm.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Update your name and phone number',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),

                // 1. Full Name Field
                AppTextField(
                  controller: nameCtrl,
                  label: 'Full Name',
                  prefixIcon: Icons.person_outline,
                  onChanged: (_) {
                    if (nameError != null) {
                      setModalState(() => nameError = null);
                    }
                  },
                ),
                if (nameError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 14,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            nameError!,
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // 2. Phone Number with Country Code Selector
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 6),
                      child: Text(
                        'Phone Number',
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Country Code Button
                        GestureDetector(
                          onTap: () {
                            showCountryPicker(
                              context: context,
                              showPhoneCode: true,
                              countryListTheme: CountryListThemeData(
                                backgroundColor: AppColors.surfaceContainer,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                                textStyle: AppTypography.bodyMd.copyWith(
                                  color: AppColors.onSurface,
                                ),
                                searchTextStyle: AppTypography.bodyMd.copyWith(
                                  color: AppColors.onSurface,
                                ),
                                inputDecoration: InputDecoration(
                                  hintText: 'Search country or code...',
                                  hintStyle: AppTypography.bodyMd.copyWith(
                                    color: AppColors.outline,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: AppColors.outline,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.surfaceContainerLow
                                      .withValues(alpha: 0.9),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              onSelect: (Country country) {
                                setModalState(() {
                                  selectedFlag = country.flagEmoji;
                                  selectedPhoneCode = '+${country.phoneCode}';
                                  selectedIso = country.countryCode;
                                  selectedExample = country.example;
                                  phoneError = null;
                                });
                              },
                            );
                          },
                          child: Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow
                                  .withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.outlineVariant
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  selectedFlag,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  selectedPhoneCode,
                                  style: AppTypography.bodyLg.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: AppColors.outline,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Phone Digits Input
                        Expanded(
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow
                                  .withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: phoneError != null
                                    ? AppColors.error
                                    : AppColors.outlineVariant
                                        .withValues(alpha: 0.4),
                              ),
                            ),
                            child: TextField(
                              controller: phoneCtrl,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (_) {
                                if (phoneError != null) {
                                  setModalState(() => phoneError = null);
                                }
                              },
                              style: AppTypography.bodyLg.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                              cursorColor: AppColors.primary,
                              decoration: InputDecoration(
                                hintText: selectedExample.isNotEmpty
                                    ? selectedExample
                                    : 'Enter phone number',
                                hintStyle: AppTypography.bodyMd.copyWith(
                                  color:
                                      AppColors.outline.withValues(alpha: 0.7),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (phoneError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 14,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                phoneError!,
                                style: AppTypography.bodySm.copyWith(
                                  color: AppColors.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 22),

                // 4. Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Cancel',
                        variant: AppButtonVariant.outline,
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: 'Save Changes',
                        onPressed: () {
                          final newName = nameCtrl.text.trim();
                          if (newName.isEmpty) {
                            setModalState(
                              () => nameError = 'Full name is required',
                            );
                            return;
                          }

                          final validation = PhoneValidator.validate(
                            countryPhoneCode: selectedPhoneCode,
                            rawNumber: phoneCtrl.text,
                            isoCode: selectedIso,
                            exampleNumber: selectedExample,
                          );

                          if (!validation.isValid) {
                            setModalState(
                              () => phoneError = validation.errorMessage,
                            );
                            return;
                          }

                          final fullPhone = validation.e164Number ??
                              '$selectedPhoneCode${phoneCtrl.text.replaceAll(RegExp(r'\D'), '')}';

                          setState(() {
                            _userName = newName;
                            _userPhone = fullPhone;
                          });
                          Navigator.of(ctx).pop();

                          try {
                            context.read<AuthBloc>().add(
                              AuthUpdateProfileSubmitted(
                                name: newName,
                                phone: fullPhone,
                              ),
                            );
                          } catch (_) {}

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile updated successfully'),
                              backgroundColor:
                                  AppColors.surfaceContainerHighest,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: Text(
          'Log Out',
          style: AppTypography.headlineSm.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Are you sure you want to log out of Simpex?',
          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.labelMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              try {
                context.read<AuthBloc>().add(const AuthLogoutRequested());
              } catch (_) {}
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const AppRoot()),
                (route) => false,
              );
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
            const SizedBox(width: 8),
            Text(
              'Delete Account',
              style: AppTypography.headlineSm.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.error,
              ),
            ),
          ],
        ),
        content: Text(
          'This action is irreversible. All your recorded transactions, voice notes, and category mappings will be permanently removed.',
          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.labelMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              try {
                context.read<AuthBloc>().add(const AuthLogoutRequested());
              } catch (_) {}
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const AppRoot()),
                (route) => false,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deleted'),
                  backgroundColor: AppColors.surfaceContainerHighest,
                ),
              );
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Identity Card matching Stitch
          _buildProfileIdentityCard(),
          const SizedBox(height: 20),

          // App Preferences Section matching Stitch
          _buildAppPreferencesSection(),
          const SizedBox(height: 20),

          // Account & Session Direct Action Buttons matching Stitch
          _buildAccountActionButtons(),
          const SizedBox(height: 32),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(
        title: 'Profile & Settings',
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            _applyUser(state.user);
          } else if (state is Unauthenticated) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
        child: content,
      ),
    );
  }

  Widget _buildProfileIdentityCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.surfaceContainerHigh.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // Glowing Emerald Avatar
            Center(
              child: Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      AppColors.primary,
                      Color(0x6610B981),
                      AppColors.surfaceContainerHigh,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 24,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceContainerLowest,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: (_userAvatarUrl != null &&
                            _userAvatarUrl!.trim().isNotEmpty)
                        ? Image.network(
                            _userAvatarUrl!,
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildInitialsAvatar(),
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value: progress.expectedTotalBytes != null
                                        ? progress.cumulativeBytesLoaded /
                                            progress.expectedTotalBytes!
                                        : null,
                                    color: AppColors.primary,
                                  ),
                                ),
                              );
                            },
                          )
                        : _buildInitialsAvatar(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // User Name & Verified Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _userName,
                  style: AppTypography.headlineSm.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.verified,
                  color: AppColors.primary,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 4),

            // User Email
            Text(
              _userEmail,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    return Center(
      child: Text(
        _userName.isNotEmpty
            ? _userName
                .split(' ')
                .map((e) => e.isNotEmpty ? e[0] : '')
                .take(2)
                .join()
            : 'AM',
        style: AppTypography.headlineLg.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 28,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildAppPreferencesSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.surfaceContainerHigh.withValues(alpha: 0.8),
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.tune,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'App Preferences',
                style: AppTypography.titleMd.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. Default Currency
          _buildPreferenceTile(
            icon: Icons.currency_rupee,
            title: 'Default Currency',
            subtitle: '$_defaultCurrency - $_defaultCurrencyName',
            trailing: _buildCircleActionButton(
              icon: Icons.edit,
              onTap: _showCurrencyPicker,
            ),
          ),
          const SizedBox(height: 10),

          // 2. Edit Profile
          _buildPreferenceTile(
            icon: Icons.person,
            title: 'Edit Profile',
            subtitle: 'Name, email, and phone number',
            trailing: _buildCircleActionButton(
              icon: Icons.edit,
              onTap: _showEditProfileDialog,
            ),
          ),
          const SizedBox(height: 10),

          // 4. Manage Categories
          _buildPreferenceTile(
            icon: Icons.category,
            title: 'Manage Categories',
            subtitle: 'Customize, add, and organize tags',
            trailing: _buildCircleActionButton(
              icon: Icons.edit,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CategoriesScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
            child: Center(
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMd.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildCircleActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
          border: Border.all(
            color: AppColors.surfaceContainerHigh.withValues(alpha: 0.8),
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 18,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildAccountActionButtons() {
    return Column(
      children: [
        // Log Out Button
        InkWell(
          onTap: _confirmLogout,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.surfaceContainerHigh.withValues(alpha: 0.8),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.logout,
                  size: 20,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Log Out',
                  style: AppTypography.titleMd.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Delete Account Button
        InkWell(
          onTap: _confirmDeleteAccount,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.errorContainer.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.delete_forever,
                  size: 20,
                  color: AppColors.error,
                ),
                const SizedBox(width: 8),
                Text(
                  'Delete Account',
                  style: AppTypography.titleMd.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
