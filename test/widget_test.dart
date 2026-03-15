import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:watchlistgo/app.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WatchlistGo());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
