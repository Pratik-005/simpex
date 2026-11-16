import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/budget/data/repositories/budget_repository.dart';
import 'package:frontend/features/budget/domain/models/budget.dart';
import 'package:frontend/features/expenses/data/mock_expense_repository.dart';
import 'package:frontend/features/expenses/domain/models/expense.dart';
import 'package:frontend/features/reports/presentation/screens/reports_screen.dart';

void main() {
  setUp(() {
    final now = DateTime.now();
    // Set up default expenses in MockExpenseRepository
    MockExpenseRepository.instance.expensesNotifier.value = [
      Expense(
        id: 'rep_1',
        merchant: 'Whole Foods Market',
        categoryId: '6ad469f73965bcc8647ee771',
        categoryName: 'Groceries',
        amountPaise: 250000, // ₹2,500.00
        date: DateTime(now.year, now.month, 5, 14, 30),
        paymentMethod: 'UPI',
        syncStatus: SyncStatus.synced,
      ),
      Expense(
        id: 'rep_2',
        merchant: 'Uber Ride',
        categoryId: '6ad469f73965bcc8647ee773',
        categoryName: 'Transport',
        amountPaise: 80000, // ₹800.00
        date: DateTime(now.year, now.month, 10, 9, 15),
        paymentMethod: 'UPI',
        syncStatus: SyncStatus.synced,
      ),
      Expense(
        id: 'rep_past',
        merchant: 'Vintage Store',
        categoryId: '6ad469f73965bcc8647ee774',
        categoryName: 'Shopping',
        amountPaise: 120000, // ₹1,200.00
        date: DateTime(now.year, now.month - 1, 15),
        paymentMethod: 'Card',
        syncStatus: SyncStatus.synced,
      ),
    ];

    // Seed budget for current month
    BudgetRepository.instance.budgetNotifier.value = Budget(
      id: 'b1',
      amountPaise: 5000000, // ₹50,000.00
      currency: 'INR',
      month: now.month,
      year: now.year,
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
    );
  });

  testWidgets('ReportsScreen renders with current month and dynamic spend', (tester) async {
    final now = DateTime.now();
    final expectedMonthTitle = DateFormat('MMMM yyyy').format(now);

    await tester.pumpWidget(
      const MaterialApp(
        home: ReportsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Expense Reports'), findsOneWidget);

    // Verify Current Month Title
    expect(find.text(expectedMonthTitle), findsOneWidget);

    // Verify Dynamic Category Allocation reflects Groceries and Transport (not hardcoded static values)
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);
    // Past month expense should not appear in current month category breakdown
    expect(find.text('Shopping'), findsNothing);
  });

  testWidgets('Month navigation buttons change month and refetch data', (tester) async {
    final now = DateTime.now();
    final currentMonthTitle = DateFormat('MMMM yyyy').format(now);
    final prevMonth = DateTime(now.year, now.month - 1, 1);
    final prevMonthTitle = DateFormat('MMMM yyyy').format(prevMonth);

    await tester.pumpWidget(
      const MaterialApp(
        home: ReportsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(currentMonthTitle), findsOneWidget);

    // Tap previous month chevron
    await tester.tap(find.byIcon(Icons.chevron_left).first);
    await tester.pumpAndSettle();

    // Should now display previous month
    expect(find.text(prevMonthTitle), findsOneWidget);

    // In previous month, Vintage Store (Shopping) was recorded, so Shopping should be present
    expect(find.text('Shopping'), findsOneWidget);
    // Current month expenses should not appear in previous month
    expect(find.text('Transport'), findsNothing);
  });

  testWidgets('Clicking date card opens Month & Year picker, selecting month refetches data', (tester) async {
    final now = DateTime.now();
    final currentMonthTitle = DateFormat('MMMM yyyy').format(now);

    await tester.pumpWidget(
      const MaterialApp(
        home: ReportsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap on the date card central area (InkWell containing month text)
    await tester.tap(find.text(currentMonthTitle));
    await tester.pumpAndSettle();

    // Verify Month & Year Picker opens
    expect(find.text('Select Month & Year'), findsOneWidget);
    expect(find.text('${now.year}'), findsOneWidget);

    // Verify month chips exist
    expect(find.text('Jan'), findsOneWidget);
    expect(find.text('Feb'), findsOneWidget);
    expect(find.text('Dec'), findsOneWidget);

    // Tap 'Jan' month chip
    await tester.tap(find.text('Jan'));
    await tester.pumpAndSettle();

    // Verify picker closed
    expect(find.text('Select Month & Year'), findsNothing);

    // Verify period updated to January of current year
    final janTitle = DateFormat('MMMM yyyy').format(DateTime(now.year, 1, 1));
    expect(find.text(janTitle), findsOneWidget);
  });

  testWidgets('Next month button is disabled when at current month', (tester) async {
    final now = DateTime.now();
    final currentMonthTitle = DateFormat('MMMM yyyy').format(now);

    await tester.pumpWidget(
      const MaterialApp(
        home: ReportsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(currentMonthTitle), findsOneWidget);

    // Attempt to tap the right chevron button
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    // Should remain on the current month because future month is disabled
    expect(find.text(currentMonthTitle), findsOneWidget);
  });

  testWidgets('Picker disables future months and years beyond current date', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final now = DateTime.now();
    final currentMonthTitle = DateFormat('MMMM yyyy').format(now);

    await tester.pumpWidget(
      const MaterialApp(
        home: ReportsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Open Month & Year Picker
    await tester.tap(find.text(currentMonthTitle));
    await tester.pumpAndSettle();

    // In current year, increment year IconButton should be disabled (onPressed == null)
    final yearRightButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_right),
    );
    expect(yearRightButton.onPressed, isNull);

    // If current month < 12, the next month should be disabled (tapping does not select or close modal)
    if (now.month < 12) {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final futureMonthName = months[now.month]; // 0-indexed, so index now.month is month (now.month + 1)
      await tester.tap(find.text(futureMonthName));
      await tester.pumpAndSettle();

      // Modal should still be open because future month chip is unclickable
      expect(find.text('Select Month & Year'), findsOneWidget);
    }

    // Now decrement the year to previous year using the year selector IconButton
    await tester.tap(find.widgetWithIcon(IconButton, Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(find.text('${now.year - 1}'), findsOneWidget);

    // Now increment year IconButton should be enabled
    final yearRightButtonPrevYear = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_right),
    );
    expect(yearRightButtonPrevYear.onPressed, isNotNull);

    // In past year, all months are selectable (e.g., Dec)
    await tester.tap(find.text('Dec'));
    await tester.pumpAndSettle();

    // Modal should close and date should be Dec of previous year
    expect(find.text('Select Month & Year'), findsNothing);
    final prevYearDecTitle = DateFormat('MMMM yyyy').format(DateTime(now.year - 1, 12, 1));
    expect(find.text(prevYearDecTitle), findsOneWidget);
  });
}

