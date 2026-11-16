import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/budget/domain/models/budget.dart';

void main() {
  group('Budget Model Tests', () {
    test('fromJson and toJson deserialize and serialize correctly', () {
      final json = {
        'id': 'budget_test_1',
        'amountMinor': 4000000, // ₹40,000
        'currency': 'INR',
        'month': 10,
        'year': 2026,
        'startDate': '2026-10-01T00:00:00.000Z',
        'endDate': '2026-10-31T23:59:59.000Z',
        'createdAt': '2026-10-01T00:00:00.000Z',
        'updatedAt': '2026-10-15T12:00:00.000Z',
      };

      final budget = Budget.fromJson(json);

      expect(budget.id, 'budget_test_1');
      expect(budget.amountPaise, 4000000);
      expect(budget.currency, 'INR');
      expect(budget.month, 10);
      expect(budget.year, 2026);

      // Verify computed methods with total spend ₹15,000 (1,500,000 paise)
      expect(budget.remainingPaise(1500000), 2500000);
      expect(budget.usageRatio(1500000), closeTo(0.375, 0.001));

      // Verify toJson
      final serialized = budget.toJson();
      expect(serialized['amountMinor'], 4000000);
      expect(serialized['currency'], 'INR');
      expect(serialized['month'], 10);
      expect(serialized['year'], 2026);
    });

    test('usageRatio calculates correctly and handles edge cases', () {
      final budget = Budget(
        id: '1',
        month: 10,
        year: 2026,
        amountPaise: 1000000,
        currency: 'INR',
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 10, 31),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(budget.usageRatio(500000), closeTo(0.5, 0.001));

      final zeroBudget = Budget(
        id: '2',
        month: 10,
        year: 2026,
        amountPaise: 0,
        currency: 'INR',
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 10, 31),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(zeroBudget.usageRatio(500000), 0.0);

      // Clamped to 1.0
      expect(budget.usageRatio(2500000), 1.0);
    });

    test('remainingPaise clamps at zero when over budget', () {
      final budget = Budget(
        id: '1',
        month: 10,
        year: 2026,
        amountPaise: 1000000,
        currency: 'INR',
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 10, 31),
      );

      expect(budget.remainingPaise(800000), 200000);
      expect(budget.remainingPaise(1200000), 0);
    });

    test('daysRemaining and dailySafeSpendPaise behave properly', () {
      final now = DateTime.now();
      final budget = Budget(
        id: '1',
        month: now.month,
        year: now.year,
        amountPaise: 3000000,
        currency: 'INR',
        startDate: DateTime(now.year, now.month, 1),
        endDate: DateTime(now.year, now.month + 1, 0),
      );

      expect(budget.daysRemaining, greaterThanOrEqualTo(0));
      expect(budget.dailySafeSpendPaise(1000000), greaterThanOrEqualTo(0));
    });

    test('copyWith updates specified fields correctly', () {
      final budget = Budget(
        id: '1',
        month: 10,
        year: 2026,
        amountPaise: 2000000,
        currency: 'INR',
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 10, 31),
      );

      final updated = budget.copyWith(
        amountPaise: 5000000,
      );

      expect(updated.id, '1');
      expect(updated.amountPaise, 5000000);
      expect(updated.currency, 'INR');
      expect(updated.month, 10);
    });
  });
}
