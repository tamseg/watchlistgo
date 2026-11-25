import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:watchlistgo/screens/watchlist_page.dart';

const _views = [
  WatchlistView<String>(
    label: 'Short',
    includes: _isShort,
    emptyMessage: 'No short words.',
  ),
  WatchlistView<String>(
    label: 'Long',
    includes: _isLong,
    emptyMessage: 'No long words.',
  ),
];

bool _isShort(String word) => word.length <= 3;
bool _isLong(String word) => word.length > 3;

Future<void> pumpPage(
  WidgetTester tester,
  List<String> items, {
  List<WatchlistView<String>> views = _views,
}) => tester.pumpWidget(
  MaterialApp(
    home: WatchlistPage<String>(
      title: 'Words',
      items: items,
      emptyIcon: Icons.abc,
      emptyLabel: 'words',
      views: views,
      itemBuilder: (word) => ListTile(key: ValueKey(word), title: Text(word)),
    ),
  ),
);

void main() {
  testWidgets('shows the first view and a count for each view', (tester) async {
    await pumpPage(tester, ['cat', 'horse', 'dog']);

    expect(find.byKey(const ValueKey('cat')), findsOneWidget);
    expect(find.byKey(const ValueKey('dog')), findsOneWidget);
    expect(find.byKey(const ValueKey('horse')), findsNothing);
    expect(find.bySemanticsLabel('Short, 2'), findsOneWidget);
    expect(find.bySemanticsLabel('Long, 1'), findsOneWidget);
  });

  testWidgets('tapping a view switches the list', (tester) async {
    await pumpPage(tester, ['cat', 'horse']);

    await tester.tap(find.bySemanticsLabel('Long, 1'));
    await tester.pump();

    expect(find.byKey(const ValueKey('horse')), findsOneWidget);
    expect(find.byKey(const ValueKey('cat')), findsNothing);
  });

  testWidgets('an empty view shows its own message', (tester) async {
    await pumpPage(tester, ['cat']);

    await tester.tap(find.bySemanticsLabel('Long, 0'));
    await tester.pump();

    expect(find.text('No long words.'), findsOneWidget);
  });

  testWidgets('an empty list shows the general empty state', (tester) async {
    await pumpPage(tester, []);

    expect(find.text('Your words watchlist is empty.'), findsOneWidget);
  });

  testWidgets('without views there is no selector and everything shows', (
    tester,
  ) async {
    await pumpPage(tester, ['cat', 'horse'], views: const []);

    expect(find.byKey(const ValueKey('cat')), findsOneWidget);
    expect(find.byKey(const ValueKey('horse')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r', \d+$')), findsNothing);
  });
}
