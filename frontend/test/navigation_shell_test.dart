import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/router/app_router.dart';
import 'package:frontend/core/widgets/app_bottom_nav_bar.dart';

void main() {
  testWidgets('Root bottom navigation bar contains Voice AI mic in the middle', (WidgetTester tester) async {
    // Navigate directly to dashboard
    AppRouter.router.go('/dashboard');

    await tester.pumpWidget(MaterialApp.router(
      routerConfig: AppRouter.router,
    ));
    await tester.pumpAndSettle();

    // Verify AppBottomNavBar is mounted
    expect(find.byType(AppBottomNavBar), findsOneWidget);

    // Verify tabs and middle Voice AI mic button
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Voice AI'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Verify mic icon is present
    expect(find.byIcon(Icons.mic), findsWidgets);

    // Tap History tab
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    // Verify AppBottomNavBar remains mounted in exact same position
    expect(find.byType(AppBottomNavBar), findsOneWidget);
    expect(find.text('Expense History'), findsOneWidget);
    expect(find.text('Voice AI'), findsOneWidget);

    // Verify Stitch Expense History elements
    expect(find.text('FILTERED SPEND'), findsOneWidget);
    expect(find.text('All Transactions'), findsOneWidget);
    expect(find.byIcon(Icons.tune), findsOneWidget);
    expect(find.text('Up to date'), findsOneWidget);
    expect(find.text('Blue Tokai Roasters'), findsOneWidget);

    // Tap on an expense item to open Stitch transaction drawer
    await tester.tap(find.text('Blue Tokai Roasters'));
    await tester.pumpAndSettle();

    expect(find.text('Voice Intelligence Transcript'), findsOneWidget);
    expect(find.text('Edit Details'), findsOneWidget);
    expect(find.text('Delete Entry'), findsOneWidget);
  });
}
