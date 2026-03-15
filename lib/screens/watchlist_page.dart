import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/series_card.dart';
import '../widgets/movie_card.dart';

class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});
  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<int> followedSeriesIds = [95479];
  List<int> followedMoviesIds = [671];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
}
