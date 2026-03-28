import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/series_card.dart';
import '../widgets/movie_card.dart';
import '../widgets/gradient_pill_switch.dart';

class WatchlistPage extends StatefulWidget {
  final List<int> followedSeriesIds;
  final List<int> followedMoviesIds;
  final void Function(int id) onRemoveSeries;
  final void Function(int id) onRemoveMovie;

  const WatchlistPage({
    required this.followedSeriesIds,
    required this.followedMoviesIds,
    required this.onRemoveSeries,
    required this.onRemoveMovie,
    super.key
  });
  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildEmptyState(String type) {
    final IconData icon = type == 'Series' ? Icons.tv : Icons.movie;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppTheme.metaIconColor.withValues(alpha: 0.5)
          ),
          const SizedBox(height: 16),
          Text(
            'Your ${type.toLowerCase()} watchlist is empty.',
            style: const TextStyle(color: AppTheme.metaIconColor, fontSize: 16)
          ),
          const SizedBox(height: 8),
          const Text(
            'Go to Search to find your favorites!',
            style: TextStyle(color: AppTheme.metaIconColor, fontSize: 16)
          )
        ]
      )
    );
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
                    style: AppTheme.watchlistPartStyle
                  ),
                  TextSpan(text: ' Go', style: AppTheme.goPartStyle)
                ]
              )
            )
          ]
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(AppTheme.appBarBottomHeight),
          child: Padding(
            padding: AppTheme.appBarBottomPadding,
            child: GradientPillSwitch(
              isMoviesSelected: _currentTabIndex == 1,
              onChanged: (isMovies) {
                _tabController.animateTo(isMovies ? 1 : 0);
              }
            )
          )
        )
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          widget.followedSeriesIds.isEmpty
              ? _buildEmptyState('Series')
              : ListView(
                  padding: const EdgeInsets.only(
                    left: 14.0,
                    right: 14.0,
                    top: 24.0,
                    bottom: 24.0
                  ),
                  children: widget.followedSeriesIds.map((id) {
                    return Padding(
                      key: ValueKey('series_$id'),
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: SeriesCard(
                        seriesId: id,
                        onRemove: () => widget.onRemoveSeries(id)
                      )
                    );
                  }).toList()
                ),
          widget.followedMoviesIds.isEmpty
              ? _buildEmptyState('Movies')
              : ListView(
                  padding: const EdgeInsets.only(
                    left: 14.0,
                    right: 14.0,
                    top: 24.0,
                    bottom: 24.0
                  ),
                  children: widget.followedMoviesIds.map((id) {
                    return Padding(
                      key: ValueKey('movie_$id'),
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: MovieCard(
                        movieId: id,
                        onRemove: () => widget.onRemoveMovie(id)
                      )
                    );
                  }).toList()
                )
        ]
      )
    );
  }
}