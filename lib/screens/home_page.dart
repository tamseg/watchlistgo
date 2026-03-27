import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'watchlist_page.dart';
import 'search_page.dart';
import 'profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
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
  SharedPreferences? _prefs;

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      followedSeriesIds = (_prefs!.getStringList('followedSeriesIds') ?? [])
          .map((id) => int.parse(id))
          .toList();
      followedMoviesIds = (_prefs!.getStringList('followedMoviesIds') ?? [])
          .map((id) => int.parse(id))
          .toList();
    });
  }

  Future<void> _savePreferences() async {
    if (_prefs == null) return;
    await _prefs!.setStringList(
      'followedSeriesIds',
      followedSeriesIds.map((id) => id.toString()).toList(),
    );
    await _prefs!.setStringList(
      'followedMoviesIds',
      followedMoviesIds.map((id) => id.toString()).toList(),
    );
  }

  void _addSeries(int id) {
    if (!followedSeriesIds.contains(id)) {
      setState(() {
        followedSeriesIds.add(id);
      });
      _savePreferences();
    }
  }

  void _addMovie(int id) {
    if (!followedMoviesIds.contains(id)) {
      setState(() {
        followedMoviesIds.add(id);
      });
      _savePreferences();
    }
  }

  void _removeSeries(int id) {
    if (followedSeriesIds.contains(id)) {
      setState(() {
        followedSeriesIds.remove(id);
      });
      _savePreferences();
    }
  }

  void _removeMovie(int id) {
    if (followedMoviesIds.contains(id)) {
      setState(() {
        followedMoviesIds.remove(id);
      });
      _savePreferences();
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initPrefs();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
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
        selectedItemColor: AppTheme.primaryColor,
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
    );
  }
}
