// test/smoke_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('smoke test: app can pump a basic widget', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('ChatMD ready')),
        ),
      ),
    );

    expect(find.text('ChatMD ready'), findsOneWidget);
  });
}
