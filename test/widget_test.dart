import 'package:flutter_test/flutter_test.dart';

import 'package:airotrack_web/main.dart';

void main() {
  testWidgets('AirotrackApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AirotrackApp());
  });
}
