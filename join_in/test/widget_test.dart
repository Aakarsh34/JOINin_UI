import 'package:flutter_test/flutter_test.dart';

import 'package:join_in/main.dart';

void main() {
  testWidgets('App boots and renders the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const JoinInApp());

    expect(find.byType(JoinInApp), findsOneWidget);
    expect(find.text('JoinIn'), findsOneWidget);

    // SplashScreen schedules a 2s navigation timer; advance past it so no
    // pending timers leak into other tests.
    await tester.pump(const Duration(seconds: 3));
  });
}
