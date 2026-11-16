import 'package:phone_numbers_parser/phone_numbers_parser.dart';

class PhoneValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? e164Number;

  const PhoneValidationResult({
    required this.isValid,
    this.errorMessage,
    this.e164Number,
  });
}

class PhoneValidator {
  PhoneValidator._();

  /// Validates a phone number based on country calling code and country ISO code.
  /// Checks whether digit count and format match the country's national telecom standards.
  static PhoneValidationResult validate({
    required String countryPhoneCode,
    required String rawNumber,
    String? isoCode,
    String? exampleNumber,
  }) {
    final cleanCode = countryPhoneCode.trim().startsWith('+')
        ? countryPhoneCode.trim()
        : '+${countryPhoneCode.trim()}';
    final digits = rawNumber.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      return const PhoneValidationResult(
        isValid: false,
        errorMessage: 'Phone number is required',
      );
    }

    final fullPhone = '$cleanCode$digits';

    int? expectedLength;
    if (exampleNumber != null && exampleNumber.isNotEmpty) {
      final exampleDigits = exampleNumber.replaceAll(RegExp(r'\D'), '');
      if (exampleDigits.isNotEmpty) {
        expectedLength = exampleDigits.length;
      }
    }

    try {
      IsoCode? countryIso;
      if (isoCode != null && isoCode.isNotEmpty) {
        for (final item in IsoCode.values) {
          if (item.name.toUpperCase() == isoCode.trim().toUpperCase()) {
            countryIso = item;
            break;
          }
        }
      }

      final PhoneNumber parsed;
      if (countryIso != null) {
        parsed = PhoneNumber.parse(digits, destinationCountry: countryIso);
      } else {
        parsed = PhoneNumber.parse(fullPhone);
      }

      final isValid =
          parsed.isValid() || parsed.isValid(type: PhoneNumberType.mobile);

      if (!isValid) {
        final lengthNote = expectedLength != null
            ? ' (expected $expectedLength digits)'
            : '';
        return PhoneValidationResult(
          isValid: false,
          errorMessage: 'Invalid phone number for $cleanCode$lengthNote',
        );
      }

      return PhoneValidationResult(
        isValid: true,
        e164Number: parsed.international,
      );
    } catch (_) {
      final lengthNote = expectedLength != null
          ? ' (expected $expectedLength digits)'
          : '';
      return PhoneValidationResult(
        isValid: false,
        errorMessage: 'Invalid phone number for $cleanCode$lengthNote',
      );
    }
  }
}
