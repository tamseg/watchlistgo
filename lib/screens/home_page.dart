import 'dart:ui';
import 'package:material_ui/material_ui.dart';
import '../theme/app_theme.dart';
import '../services/watchlist_repository.dart';
import 'watchlist_page.dart';
import 'search_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  final WatchlistRepository repository;

  const HomePage({super.key, required this.repository});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late PageController _pageController;
  int _bottomNavIndex = 0;
  final GlobalKey<SearchPageState> _searchPageKey =
      GlobalKey<SearchPageState>();

  List<int> followedSeriesIds = [];
  List<int> followedMoviesIds = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    followedSeriesIds = widget.repository.currentSeriesIds.toList();
    followedMoviesIds = widget.repository.currentMoviesIds.toList();

    widget.repository.seriesStream.listen((ids) {
      if (mounted) setState(() => followedSeriesIds = ids.toList());
    });
    widget.repository.moviesStream.listen((ids) {
      if (mounted) setState(() => followedMoviesIds = ids.toList());
    });
  }

  void _addSeries(int id) => widget.repository.addSeries(id);

  void _addMovie(int id) => widget.repository.addMovie(id);

  void _removeSeries(int id) => widget.repository.removeSeries(id);

  void _removeMovie(int id) => widget.repository.removeMovie(id);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _bottomNavIndex = index;
          });
          if (index == 1) {
            Future.delayed(const Duration(milliseconds: 400), () {
              if (_bottomNavIndex == 1) {
                _searchPageKey.currentState?.requestSearchFocus();
              }
            });
          } else {
            _searchPageKey.currentState?.unfocusSearch();
          }
        },
        children: [
          WatchlistPage(
            followedSeriesIds: followedSeriesIds,
            followedMoviesIds: followedMoviesIds,
            onRemoveSeries: _removeSeries,
            onRemoveMovie: _removeMovie,
          ),
          SearchPage(
            key: _searchPageKey,
            followedSeriesIds: followedSeriesIds,
            followedMoviesIds: followedMoviesIds,
            onAddSeries: _addSeries,
            onAddMovie: _addMovie,
          ),
          ProfilePage(repository: widget.repository),
        ],
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppTheme.glassBlurSigma,
            sigmaY: AppTheme.glassBlurSigma,
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.white.withValues(
              alpha: AppTheme.glassOpacity,
            ),
            elevation: 0,
            currentIndex: _bottomNavIndex,
            onTap: (index) {
              setState(() {
                _bottomNavIndex = index;
              });
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            showSelectedLabels: false,
            showUnselectedLabels: false,
            iconSize: 30.0,
            selectedItemColor: AppTheme.navActiveColor,
            unselectedItemColor: AppTheme.metaIconColor,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search_outlined),
                activeIcon: Icon(Icons.search),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
