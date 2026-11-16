import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/app.dart';

void main() {
  testWidgets('Simpex smoke test launches login entry screen via AppRoot', (WidgetTester tester) async {
    await tester.pumpWidget(const SimpexApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Simpex'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
