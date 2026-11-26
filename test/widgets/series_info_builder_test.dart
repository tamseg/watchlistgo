import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:watchlistgo/models/series_info.dart';
import 'package:watchlistgo/services/series_info_service.dart';
import 'package:watchlistgo/widgets/series_info_builder.dart';

const ready = (
  status: SeriesInfoStatus.ready,
  info: SeriesInfo(state: SeriesState.ended),
);

Future<StreamController<SeriesInfoState>> pumpBuilder(
  WidgetTester tester,
) async {
  final controller = StreamController<SeriesInfoState>();
  addTearDown(controller.close);
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: SeriesInfoBuilder(
        seriesId: 1,
        watch: (_) => controller.stream,
        patience: const Duration(seconds: 30),
        builder: (context, state) => Text(state.status.name),
      ),
    ),
  );
  return controller;
}

void main() {
  testWidgets('waits while the show is being resolved', (tester) async {
    final controller = await pumpBuilder(tester);
    controller.add(loadingSeriesInfo);
    await tester.pumpAndSettle();
    expect(find.text('loading'), findsOneWidget);

    controller.add(ready);
    await tester.pumpAndSettle();
    expect(find.text('ready'), findsOneWidget);
  });

  testWidgets('gives up after its patience runs out', (tester) async {
    await pumpBuilder(tester);
    await tester.pump(const Duration(seconds: 31));
    expect(find.text('unavailable'), findsOneWidget);
  });

  testWidgets('shows data that arrives after giving up', (tester) async {
    final controller = await pumpBuilder(tester);
    await tester.pump(const Duration(seconds: 31));
    controller.add(ready);
    await tester.pumpAndSettle();
    expect(find.text('ready'), findsOneWidget);
  });

  testWidgets('an unreadable show is unavailable right away', (tester) async {
    final controller = await pumpBuilder(tester);
    controller.add(unavailableSeriesInfo);
    await tester.pumpAndSettle();
    expect(find.text('unavailable'), findsOneWidget);
  });
}
