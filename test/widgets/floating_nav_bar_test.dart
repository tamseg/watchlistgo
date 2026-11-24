import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:watchlistgo/widgets/floating_nav_bar.dart';

const _items = [
  FloatingNavItem(
    icon: Icons.tv_outlined,
    activeIcon: Icons.tv,
    label: 'Series',
  ),
  FloatingNavItem(
    icon: Icons.movie_outlined,
    activeIcon: Icons.movie,
    label: 'Movies',
  ),
  FloatingNavItem(
    icon: Icons.search_outlined,
    activeIcon: Icons.search,
    label: 'Search',
  ),
  FloatingNavItem(
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    label: 'Profile',
  ),
];

Future<List<int>> pumpNavBar(
  WidgetTester tester, {
  int currentIndex = 0,
}) async {
  final taps = <int>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        bottomNavigationBar: FloatingNavBar(
          items: _items,
          currentIndex: currentIndex,
          onTap: taps.add,
        ),
      ),
    ),
  );
  return taps;
}

void main() {
  testWidgets('exposes each tab to screen readers', (tester) async {
    await pumpNavBar(tester, currentIndex: 1);

    for (final item in _items) {
      expect(find.bySemanticsLabel(item.label), findsOneWidget);
    }
    expect(
      tester.getSemantics(find.bySemanticsLabel('Movies')),
      isSemantics(isButton: true, isSelected: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Series')),
      isSemantics(isButton: true, isSelected: false),
    );
  });

  testWidgets('tapping an icon selects its tab', (tester) async {
    final taps = await pumpNavBar(tester);

    await tester.tap(find.byIcon(Icons.search_outlined));
    await tester.tap(find.byIcon(Icons.movie_outlined));

    expect(taps, [2, 1]);
  });

  testWidgets('taps below or beside the pill go to the nearest tab', (
    tester,
  ) async {
    final taps = await pumpNavBar(tester);
    final bar = tester.getRect(find.byType(FloatingNavBar));

    await tester.tapAt(Offset(bar.right - 4, bar.bottom - 4));
    await tester.tapAt(Offset(bar.left + 4, bar.bottom - 4));

    expect(taps, [3, 0]);
  });
}
