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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: AppTheme.buildFrostedGlassBackground(),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(AppTheme.appBarBottomHeight),
          child: Padding(
            padding: AppTheme.appBarBottomPadding,
            child: AnimatedBuilder(
              animation: _tabController.animation!,
              builder: (context, child) {
                return GradientPillSwitch(
                  animationValue: _tabController.animation!.value,
                  onChanged: (isMovies) {
                    _tabController.animateTo(isMovies ? 1 : 0);
                  }
                );
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
                    top: 130.0,
                    bottom: 64.0
                  ),
                  children: widget.followedSeriesIds.map((id) {
                    return SeriesCard(
                      key: ValueKey('series_$id'),
                      seriesId: id,
                      onRemove: () => widget.onRemoveSeries(id)
                    );
                  }).toList()
                ),
          widget.followedMoviesIds.isEmpty
              ? _buildEmptyState('Movies')
              : ListView(
                  padding: const EdgeInsets.only(
                    left: 14.0,
                    right: 14.0,
                    top: 130.0,
                    bottom: 64.0
                  ),
                  children: widget.followedMoviesIds.map((id) {
                    return MovieCard(
                      key: ValueKey('movie_$id'),
                      movieId: id,
                      onRemove: () => widget.onRemoveMovie(id)
                    );
                  }).toList()
                )
        ]
      )
    );
  }
}
