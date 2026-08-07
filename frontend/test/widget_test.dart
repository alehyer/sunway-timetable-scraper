import 'package:flutter_test/flutter_test.dart';
import 'package:sunway_scheduler/main.dart';

void main() {
  testWidgets('Sunway Scheduler app loads', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SunwayApp());

    expect(find.text('Sunway'), findsOneWidget);
  });
}
