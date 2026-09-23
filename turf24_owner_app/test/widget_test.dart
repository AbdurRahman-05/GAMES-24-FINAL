import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:playhub_madurai/main.dart';

void main() {
  testWidgets('PlayHub App Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PlayHubApp(),
      ),
    );
    expect(find.text('PlayHub Madurai'), findsOneWidget);
  });
}
