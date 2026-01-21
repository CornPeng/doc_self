import 'package:flutter_test/flutter_test.dart';
import 'package:soul_note/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SoulNoteApp());
    expect(find.text('SoulNote'), findsOneWidget);
  });
}
