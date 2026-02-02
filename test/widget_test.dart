import 'package:flutter_test/flutter_test.dart';
import 'package:whispr/main.dart';

void main() {
  testWidgets('Whispr smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WhisprApp());

    // Verify that "Whispr" is present
    expect(find.text('Whispr'), findsOneWidget);
  });
}
