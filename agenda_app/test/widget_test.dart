import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_app/main.dart';

void main() {
  testWidgets('AgendaApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AgendaApp());
    expect(find.byType(AgendaApp), findsOneWidget);
  });
}
