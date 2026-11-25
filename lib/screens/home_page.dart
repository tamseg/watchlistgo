import 'dart:async';
import 'package:material_ui/material_ui.dart';
import '../services/watchlist_repository.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/movie_card.dart';
import '../widgets/series_card.dart';
import 'watchlist_page.dart';
import 'search_page.dart';
import 'profile_page.dart';
import '../theme/theme_controller.dart';

const int _seriesPageIndex = 0;
const int _searchPageIndex = 2;

class HomePage extends StatefulWidget {
  final WatchlistRepository repository;
  final ThemeController themeController;

  const HomePage({
    super.key,
    required this.repository,
    required this.themeController,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PageController _pageController;

  final ValueNotifier<int> _pageIndex = ValueNotifier(_seriesPageIndex);

  bool _isTapAnimating = false;

  final GlobalKey<SearchPageState> _searchPageKey =
      GlobalKey<SearchPageState>();

  List<int> followedSeriesIds = [];
  List<int> followedMoviesIds = [];
  late final StreamSubscription<Iterable<int>> _seriesSub;
  late final StreamSubscription<Iterable<int>> _moviesSub;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    followedSeriesIds = widget.repository.currentSeriesIds.toList();
    followedMoviesIds = widget.repository.currentMoviesIds.toList();

    _seriesSub = widget.repository.seriesStream.listen((ids) {
      if (mounted) setState(() => followedSeriesIds = ids.toList());
    });
    _moviesSub = widget.repository.moviesStream.listen((ids) {
      if (mounted) setState(() => followedMoviesIds = ids.toList());
    });
  }

  void _addSeries(int id, String? title) =>
      widget.repository.addSeries(id, title: title);

  void _addMovie(int id, String? title) =>
      widget.repository.addMovie(id, title: title);

  void _removeSeries(int id) => widget.repository.removeSeries(id);

  void _removeMovie(int id) => widget.repository.removeMovie(id);

  void _onPageChanged(int index) {
    if (!_isTapAnimating) _pageIndex.value = index;

    if (index == _searchPageIndex) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (_pageIndex.value == _searchPageIndex) {
          _searchPageKey.currentState?.requestSearchFocus();
        }
      });
    } else {
      _searchPageKey.currentState?.unfocusSearch();
    }
  }

  Future<void> _onNavTap(int index) async {
    if (index == _pageIndex.value) return;
    _pageIndex.value = index;
    _isTapAnimating = true;
    try {
      await _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } finally {
      _isTapAnimating = false;
    }
    if (mounted && _pageController.hasClients) {
      _pageIndex.value = _pageController.page!.round();
    }
  }

  @override
  void dispose() {
    _seriesSub.cancel();
    _moviesSub.cancel();
    _pageIndex.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          _KeepAlivePage(
            child: WatchlistPage(
              title: 'Series',
              ids: followedSeriesIds,
              emptyIcon: Icons.tv,
              emptyLabel: 'series',
              itemBuilder: (id) => SeriesCard(
                key: ValueKey('series_$id'),
                seriesId: id,
                onRemove: () => _removeSeries(id),
              ),
            ),
          ),
          _KeepAlivePage(
            child: WatchlistPage(
              title: 'Movies',
              ids: followedMoviesIds,
              emptyIcon: Icons.movie,
              emptyLabel: 'movies',
              itemBuilder: (id) => MovieCard(
                key: ValueKey('movie_$id'),
                movieId: id,
                onRemove: () => _removeMovie(id),
              ),
            ),
          ),
          _KeepAlivePage(
            child: SearchPage(
              key: _searchPageKey,
              followedSeriesIds: followedSeriesIds,
              followedMoviesIds: followedMoviesIds,
              onAddSeries: _addSeries,
              onAddMovie: _addMovie,
            ),
          ),
          _KeepAlivePage(
            child: ProfilePage(
              repository: widget.repository,
              themeController: widget.themeController,
            ),
          ),
        ],
      ),
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: _pageIndex,
        builder: (context, index, _) => FloatingNavBar(
          currentIndex: index,
          onTap: _onNavTap,
          items: const [
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
          ],
        ),
      ),
    );
  }
}

class _KeepAlivePage extends StatefulWidget {
  final Widget child;

  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
