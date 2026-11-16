import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/categories/presentation/screens/category_expenses_screen.dart';
import 'package:frontend/features/expenses/data/mock_expense_repository.dart';
import 'package:frontend/features/expenses/domain/models/expense.dart';

void main() {
  testWidgets('CategoryExpensesScreen renders simplified 2-column grid and shows transactions on tap', (WidgetTester tester) async {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 15);

    // Seed an expense for this month and one for last month
    MockExpenseRepository.instance.expensesNotifier.value = [
      Expense(
        id: 'test_1',
        merchant: 'Organic Supermarket',
        categoryId: '6ad469f73965bcc8647ee771',
        categoryName: 'Groceries',
        amountPaise: 450000,
        date: now,
        paymentMethod: 'UPI',
        syncStatus: SyncStatus.synced,
      ),
      Expense(
        id: 'test_past',
        merchant: 'Old Mart',
        categoryId: '6ad469f73965bcc8647ee771',
        categoryName: 'Groceries',
        amountPaise: 990000,
        date: lastMonth,
        paymentMethod: 'Cash',
        syncStatus: SyncStatus.synced,
      ),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: CategoryExpensesScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify AppBar title is 'Categories'
    expect(find.text('Categories'), findsOneWidget);

    // Verify filter, searchbar and spending summary cards are removed
    expect(find.text('Category Breakdown'), findsNothing);
    expect(find.text('Total Category Spending'), findsNothing);
    expect(find.text('This Month'), findsNothing);

    // Groceries should be visible in the 2-column grid
    expect(find.text('Groceries'), findsWidgets);

    // Tap on Groceries card to view transactions bottom sheet
    final groceriesFinder = find.text('Groceries').first;
    await tester.tap(groceriesFinder);
    await tester.pumpAndSettle();

    // Verify bottom sheet shows transactions for Groceries for this month only
    expect(find.text('Organic Supermarket'), findsOneWidget);
    expect(find.text('Old Mart'), findsNothing);
  });
}
