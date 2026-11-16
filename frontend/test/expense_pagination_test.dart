import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/expenses/data/mock_expense_repository.dart';
import 'package:frontend/features/expenses/domain/models/expense.dart';
import 'package:frontend/features/expenses/domain/models/paginated_expenses.dart';
import 'package:frontend/features/expenses/presentation/screens/history_screen.dart';

void main() {
  group('PaginatedExpenses Model Tests', () {
    test('deserializes JSON properly and parses pagination flags', () {
      final json = {
        'success': true,
        'data': [
          {
            '_id': 'exp_1',
            'description': 'Blue Tokai Coffee',
            'categoryId': {
              '_id': 'cat_1',
              'name': 'Dining',
              'color': '#10B981',
              'icon': 'restaurant',
            },
            'amountMinor': 38000,
            'currency': 'INR',
            'transactionDate': '2026-10-25T12:00:00.000Z',
            'paymentMethod': 'UPI',
          },
        ],
        'pagination': {
          'page': 1,
          'limit': 20,
          'total': 45,
          'totalPages': 3,
          'hasMore': true,
          'nextPage': 2,
        },
      };

      final paginated = PaginatedExpenses.fromJson(json);

      expect(paginated.items.length, 1);
      expect(paginated.items.first.merchant, 'Blue Tokai Coffee');
      expect(paginated.page, 1);
      expect(paginated.limit, 20);
      expect(paginated.total, 45);
      expect(paginated.totalPages, 3);
      expect(paginated.hasMore, isTrue);
      expect(paginated.nextPage, 2);
    });

    test('defaults gracefully when pagination object is missing', () {
      final json = {
        'success': true,
        'data': [],
      };

      final paginated = PaginatedExpenses.fromJson(json);

      expect(paginated.items, isEmpty);
      expect(paginated.page, 1);
      expect(paginated.total, 0);
      expect(paginated.hasMore, isFalse);
      expect(paginated.nextPage, isNull);
    });
  });

  group('HistoryScreen Infinite Scroll UI Tests', () {
    testWidgets('renders HistoryScreen with infinite scroll elements and end indicator', (WidgetTester tester) async {
      // Seed expenses
      final now = DateTime.now();
      MockExpenseRepository.instance.expensesNotifier.value = [
        Expense(
          id: 'test_item_1',
          merchant: 'Starbucks Reserve',
          categoryId: 'dining',
          categoryName: 'Dining',
          amountPaise: 55000,
          date: now,
          paymentMethod: 'UPI',
        ),
      ];
      MockExpenseRepository.instance.setPaginationStateForTesting(
        currentPage: 1,
        hasMore: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header & Transaction Item
      expect(find.text('Expense History'), findsOneWidget);
      expect(find.text('Starbucks Reserve'), findsOneWidget);

      // Verify end-of-list indicator is not shown (removed per user design)
      expect(find.text("You've viewed all transactions"), findsNothing);

      // Test isLoadingMore spinner toggle
      MockExpenseRepository.instance.isLoadingMoreNotifier.value = true;
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      MockExpenseRepository.instance.isLoadingMoreNotifier.value = false;
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Filter bottom sheet opens with date range, categories without all-categories option, and Clear/Apply buttons', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap tune/filter button
      final filterBtn = find.byIcon(Icons.tune);
      expect(filterBtn, findsOneWidget);
      await tester.tap(filterBtn);
      await tester.pumpAndSettle();

      // Verify filter sheet contents
      expect(find.text('Filter Transactions'), findsOneWidget);
      expect(find.text('From Date'), findsOneWidget);
      expect(find.text('To Date'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);

      // Verify 'All Categories' option is removed
      expect(find.text('All Categories'), findsNothing);

      // Verify individual categories exist (e.g. Food & Dining, Transport)
      expect(find.text('Food & Dining'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);

      // Tap Transport category chip inside bottom sheet
      await tester.tap(find.text('Transport'));
      await tester.pumpAndSettle();

      // Tap Apply
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      // Verify filter sheet closed and active category pill is visible on HistoryScreen
      expect(find.text('Filter Transactions'), findsNothing);
      expect(find.text('Category: Transport'), findsOneWidget);

      // Re-open filter sheet and test Clear button
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      expect(find.text('Filter Transactions'), findsOneWidget);

      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      // Verify filter sheet closed and active category pill is removed (all categories)
      expect(find.text('Filter Transactions'), findsNothing);
      expect(find.text('Category: Transport'), findsNothing);
    });
  });
}
