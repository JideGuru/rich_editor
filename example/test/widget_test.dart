import 'package:example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('lists the demos', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Basic demo'), findsOneWidget);
    expect(find.text('Custom toolbar demo'), findsOneWidget);
  });
}
