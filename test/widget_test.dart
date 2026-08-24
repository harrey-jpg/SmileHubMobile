import 'package:flutter_test/flutter_test.dart';
import 'package:smilehub_flutter/app.dart';

void main() {
  testWidgets('SmileHub starts on onboarding screen', (tester) async {
    await tester.pumpWidget(const SmileHubApp());
    await tester.pumpAndSettle();

    expect(find.text('SmileHub'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
