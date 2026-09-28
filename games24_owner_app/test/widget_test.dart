import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:games24_owner_app/main.dart';

void main() {
  testWidgets('Games24 App Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: Games24OwnerApp(),
      ),
    );
    expect(find.text('Games24 Owner'), findsOneWidget);
  });
}
