import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/series_card.dart';
import '../widgets/movie_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  int _bottomNavIndex = 0;
  List<int> followedSeriesIds = [95479];
  List<int> followedMoviesIds = [671];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pageController = PageController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildHomeTab() {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo.webp', height: 40),
            const SizedBox(width: 10),
            RichText(
              text: const TextSpan(
                style: AppTheme.appBarTitleStyle,
                children: [
                  TextSpan(
                    text: 'Watchlist',
                    style: AppTheme.watchlistPartStyle,
                  ),
                  TextSpan(text: ' Go', style: AppTheme.goPartStyle),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(AppTheme.appBarBottomHeight),
          child: Padding(
            padding: AppTheme.appBarBottomPadding,
            child: Container(
              height: AppTheme.tabContainerHeight,
              width: AppTheme.tabContainerWidth,
              decoration: AppTheme.tabTrackDecoration,
              child: AppTheme.styledTabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Series'),
                  Tab(text: 'Movies'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ListView.builder(
            padding: const EdgeInsets.only(left: 14.0, right: 14.0, top: 24.0),
            itemCount: followedSeriesIds.length,
            itemBuilder: (context, index) {
              final id = followedSeriesIds[index];
              return SeriesCard(seriesId: id);
            },
          ),
          ListView.builder(
            padding: const EdgeInsets.only(left: 14.0, right: 14.0, top: 24.0),
            itemCount: followedMoviesIds.length,
            itemBuilder: (context, index) {
              final id = followedMoviesIds[index];
              return MovieCard(movieId: id);
            },
          ),
        ],
      ),
    );
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
        },
        children: [
          _buildHomeTab(),
          const Scaffold(
            body: Center(child: Text('Search Page comming soon...')),
          ),
          const Scaffold(
            body: Center(child: Text('Profile Page comming soon...')),
          ),
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
