import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/utils/phone_validator.dart';
import 'package:luthor/luthor.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

String? extractError(ValidationResult result) {
  if (result.isValid) return null;
  final errors = result.errors;
  if (errors.isEmpty) return null;
  final firstVal = errors.values.first;
  if (firstVal.isNotEmpty) {
    return firstVal.first;
  }
  return null;
}

void main() {
  test('Luthor extractError helper', () {
    final emailValidator = l
        .string()
        .email(message: 'Invalid email address')
        .required(message: 'Email is required');

    final result = emailValidator.validate('bad-email');
    expect(result.isValid, isFalse);
    expect(extractError(result), equals('Invalid email address'));

    final validResult = emailValidator.validate('alex@gmail.com');
    expect(validResult.isValid, isTrue);
    expect(extractError(validResult), isNull);
  });

  test('phone_numbers_parser validates digit counts per country code', () {
    // India (+91) requires 10 digits for mobile
    final validIn = PhoneNumber.parse('+919876543210');
    expect(validIn.isValid(), isTrue);

    // Too short for India mobile (8 digits)
    final shortIn = PhoneNumber.parse('+9198765432');
    expect(shortIn.isValid(type: PhoneNumberType.mobile), isFalse);

    // US (+1) requires 10 digits
    final validUs = PhoneNumber.parse('+12025550119');
    expect(validUs.isValid(), isTrue);

    // Too short for US (7 digits)
    final shortUs = PhoneNumber.parse('+12025550');
    expect(shortUs.isValid(), isFalse);
  });

  test('PhoneValidator utility validates correctly and produces helpful messages', () {
    // Empty
    final emptyRes = PhoneValidator.validate(countryPhoneCode: '+91', rawNumber: '');
    expect(emptyRes.isValid, isFalse);
    expect(emptyRes.errorMessage, equals('Phone number is required'));

    // Valid India
    final validIn = PhoneValidator.validate(
      countryPhoneCode: '+91',
      rawNumber: '9876543210',
      isoCode: 'IN',
      exampleNumber: '9123456789',
    );
    expect(validIn.isValid, isTrue);
    expect(validIn.e164Number, equals('+919876543210'));

    // Invalid India (too short)
    final invalidIn = PhoneValidator.validate(
      countryPhoneCode: '+91',
      rawNumber: '9876543',
      isoCode: 'IN',
      exampleNumber: '9123456789',
    );
    expect(invalidIn.isValid, isFalse);
    expect(invalidIn.errorMessage, contains('expected 10 digits'));

    // Valid US
    final validUs = PhoneValidator.validate(
      countryPhoneCode: '+1',
      rawNumber: '2025550119',
      isoCode: 'US',
      exampleNumber: '2015550123',
    );
    expect(validUs.isValid, isTrue);
    expect(validUs.e164Number, equals('+12025550119'));

    // Invalid US (too short)
    final invalidUs = PhoneValidator.validate(
      countryPhoneCode: '+1',
      rawNumber: '202555',
      isoCode: 'US',
      exampleNumber: '2015550123',
    );
    expect(invalidUs.isValid, isFalse);
    expect(invalidUs.errorMessage, contains('expected 10 digits'));
  });
}
