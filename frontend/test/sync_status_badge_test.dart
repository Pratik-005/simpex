import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/sync_status_badge.dart';
import 'package:frontend/features/expenses/domain/models/expense.dart';

void main() {
  testWidgets('SyncStatusBadge takes entire width by default', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SyncStatusBadge(status: SyncStatus.synced),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('All synced with cloud • 100%'), findsOneWidget);

    final badgeFinder = find.byType(SyncStatusBadge);
    expect(badgeFinder, findsOneWidget);

    final size = tester.getSize(badgeFinder);
    expect(size.width, 360.0);
  });

  testWidgets('SyncStatusBadge renders pending count in offline mode', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SyncStatusBadge(
            status: SyncStatus.pending,
            pendingCount: 3,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3 pending sync (offline queue)'), findsOneWidget);
  });
}
