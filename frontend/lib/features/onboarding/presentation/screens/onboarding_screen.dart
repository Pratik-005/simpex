import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import '../../../../app/main_shell_page.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/constants/currency_constants.dart';
import '../../../../core/injection/init_dependencies.dart';
import '../../../../core/storage/auth_storage.dart';
import '../../../../core/utils/phone_validator.dart';
import '../../../../core/utils/show_snackbar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../../authentication/domain/usecases/update_profile_use_case.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;

  String _countryFlag = '🇮🇳';
  String _countryPhoneCode = '+91';
  String _countryIsoCode = 'IN';
  String _countryExample = '9123456789';

  String _selectedCurrency = 'INR';
  String _currencySymbol = '₹';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    String initialFirst = '';
    String initialLast = '';
    String initialPhone = '';

    try {
      if (sl.isRegistered<AuthStorage>()) {
        final user = sl<AuthStorage>().getUser();
        if (user != null) {
          if (user.name.isNotEmpty) {
            final parts = user.name.trim().split(RegExp(r'\s+'));
            initialFirst = parts.first;
            if (parts.length > 1) {
              initialLast = parts.sublist(1).join(' ');
            }
          }
          if (user.currency.isNotEmpty) {
            final item = CurrencyConstants.find(user.currency);
            _selectedCurrency = item.code;
            _currencySymbol = item.symbol;
          }
          if (user.phone != null && user.phone!.isNotEmpty) {
            final p = user.phone!;
            if (p.startsWith('+91') && p.length > 3) {
              _countryPhoneCode = '+91';
              initialPhone = p.substring(3);
            } else if (p.startsWith('+1') && p.length > 2) {
              _countryPhoneCode = '+1';
              _countryFlag = '🇺🇸';
              initialPhone = p.substring(2);
            } else {
              initialPhone = p;
            }
          }
        }
      }
    } catch (_) {}

    _firstNameController = TextEditingController(text: initialFirst);
    _lastNameController = TextEditingController(text: initialLast);
    _phoneController = TextEditingController(text: initialPhone);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onCurrencyChanged(String? newCode) {
    if (newCode == null) return;
    final item = CurrencyConstants.find(newCode);
    setState(() {
      _selectedCurrency = item.code;
      _currencySymbol = item.symbol;
    });
  }

  void _pickCurrency() {
    String searchQuery = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
                  'Select Preferred Currency',
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
                            final isSelected = curr.code == _selectedCurrency;
                            return InkWell(
                              onTap: () {
                                _onCurrencyChanged(curr.code);
                                Navigator.of(ctx).pop();
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 8,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary
                                                .withValues(alpha: 0.15)
                                            : AppColors.surfaceContainerLow,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                                  .withValues(alpha: 0.4)
                                              : AppColors.cardBorder,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          curr.symbol,
                                          style: AppTypography.titleMd.copyWith(
                                            color: isSelected
                                                ? AppColors.primary
                                                : AppColors.onSurface,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            curr.displayName,
                                            style:
                                                AppTypography.titleMd.copyWith(
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              fontSize: 14,
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.onSurface,
                                            ),
                                          ),
                                          Text(
                                            curr.code,
                                            style: AppTypography.bodySm.copyWith(
                                              color: AppColors.outline,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
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

  void _pickCountryCode() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      countryListTheme: CountryListThemeData(
        backgroundColor: AppColors.surfaceContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        textStyle: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
        searchTextStyle: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
        inputDecoration: InputDecoration(
          hintText: 'Search country or code...',
          hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.outline),
          prefixIcon: const Icon(Icons.search, color: AppColors.outline),
          filled: true,
          fillColor: AppColors.surfaceContainerLowest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
      onSelect: (Country country) {
        setState(() {
          _countryFlag = country.flagEmoji;
          _countryPhoneCode = '+${country.phoneCode}';
          _countryIsoCode = country.countryCode;
          _countryExample = country.example;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Ambient Glow
          Positioned(
            top: -50,
            left: MediaQuery.of(context).size.width / 2 - 120,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  Text(
                    "Let's set up your profile",
                    style: AppTypography.headlineLg.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Simpex personalizes speech recognition and currency formatting based on these details.',
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Bento Row 1: First & Last Name
                  Row(
                    children: [
                      Expanded(
                        child: BentoCard(
                          padding: const EdgeInsets.all(12),
                          backgroundColor: AppColors.surfaceContainerLow,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'FIRST NAME',
                                    style: AppTypography.labelSm.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.outline,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.badge,
                                    size: 14,
                                    color: AppColors.outline,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _firstNameController,
                                style: AppTypography.titleMd.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: BentoCard(
                          padding: const EdgeInsets.all(12),
                          backgroundColor: AppColors.surfaceContainerLow,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'LAST NAME',
                                    style: AppTypography.labelSm.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.outline,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.person,
                                    size: 14,
                                    color: AppColors.outline,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _lastNameController,
                                style: AppTypography.titleMd.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Bento Row 2: Phone Number
                  BentoCard(
                    padding: const EdgeInsets.all(14),
                    backgroundColor: AppColors.surfaceContainerLow,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PHONE NUMBER',
                          style: AppTypography.labelSm.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.outline,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _pickCountryCode,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _countryFlag,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _countryPhoneCode,
                                      style: AppTypography.titleMd.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(
                                      Icons.expand_more,
                                      size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                style: AppTypography.titleMd.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Bento Row 3: Preferred Currency Selector Card
                  BentoCard(
                    padding: const EdgeInsets.all(14),
                    backgroundColor: AppColors.surfaceContainerLow,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PREFERRED BASE CURRENCY',
                              style: AppTypography.labelSm.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.outline,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Primary',
                                style: AppTypography.labelSm.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: _pickCurrency,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.cardBorder,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _currencySymbol,
                                      style: AppTypography.titleMd.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        CurrencyConstants.find(
                                                _selectedCurrency)
                                            .displayName,
                                        style:
                                            AppTypography.titleMd.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Tap to change currency',
                                        style: AppTypography.bodySm.copyWith(
                                          color: AppColors.outline,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.unfold_more,
                                  color: AppColors.textSecondary,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    label: 'Continue',
                    icon: Icons.arrow_forward,
                    isTrailingIcon: true,
                    isLoading: _isSaving,
                    onPressed: _onContinue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onContinue() async {
    final firstName = _firstNameController.text.trim();
    if (firstName.isEmpty) {
      showSnackbar(context, 'Please enter your first name');
      return;
    }

    final rawPhone = _phoneController.text.replaceAll(RegExp(r'[\s\-]'), '');
    if (rawPhone.isEmpty) {
      showSnackbar(context, 'Please enter your phone number');
      return;
    }

    final validation = PhoneValidator.validate(
      countryPhoneCode: _countryPhoneCode,
      rawNumber: _phoneController.text,
      isoCode: _countryIsoCode,
      exampleNumber: _countryExample,
    );
    if (!validation.isValid) {
      showSnackbar(
        context,
        validation.errorMessage ?? 'Please enter a valid phone number',
      );
      return;
    }

    final fullPhone = validation.e164Number ?? '$_countryPhoneCode$rawPhone';

    final fullName = '$firstName ${_lastNameController.text.trim()}'.trim();

    setState(() => _isSaving = true);

    try {
      if (sl.isRegistered<UpdateProfileUseCase>()) {
        final result = await sl<UpdateProfileUseCase>()(
          UpdateProfileParams(
            name: fullName,
            phone: fullPhone,
            currency: _selectedCurrency,
            locale: 'en_IN',
          ),
        );

        if (!mounted) return;

        bool success = false;
        result.fold(
          (failure) {
            showSnackbar(context, failure.message);
          },
          (user) {
            success = true;
          },
        );

        if (!success) {
          setState(() => _isSaving = false);
          return;
        }
      }

      if (sl.isRegistered<AuthStorage>()) {
        await sl<AuthStorage>().setCompletedOnboarding(true);
      }

      if (!mounted) return;

      try {
        context.read<AuthBloc>().add(const AuthCheckRequested());
      } catch (_) {}

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainShellPage()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        showSnackbar(context, e.toString());
        setState(() => _isSaving = false);
      }
    }
  }
}
