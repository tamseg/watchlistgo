import 'package:flutter/material.dart';
import '../services/tmdb_service.dart';
import '../screens/series_detail_page.dart';
import 'media_card.dart';
import 'action_menu.dart';

class SeriesCard extends StatefulWidget {
  final int seriesId;
  final VoidCallback onRemove;

  const SeriesCard({required this.seriesId, required this.onRemove, super.key});

  @override
  State<SeriesCard> createState() => _SeriesCardState();
}

class _SeriesCardState extends State<SeriesCard>
    with AutomaticKeepAliveClientMixin {
  late Future<Map<String, dynamic>?> _seriesData;
  final TMDBService _tmdbService = TMDBService();

  @override
  void initState() {
    super.initState();
    _seriesData = _tmdbService.getDetails('tv', widget.seriesId);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<Map<String, dynamic>?>(
      future: _seriesData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MediaCard(
            title: 'Loading...',
            subtitleWidget: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return MediaCard(
            title: 'Error loading series',
            subtitle: 'Tap to retry',
            trailing: ActionMenu(onRemove: widget.onRemove),
          );
        }

        final data = snapshot.data!;
        final seriesTitle = data['name'] ?? 'Unknown Title';
        final posterPath = data['poster_path'];
        final posterUrl = posterPath != null
            ? 'https://image.tmdb.org/t/p/w200$posterPath'
            : null;

        final nextEpisode = data['next_episode_to_air'];
        final lastEpisode = data['last_episode_to_air'];

        Widget subtitleWidget;
        final theme = Theme.of(context).textTheme;

        if (nextEpisode != null) {
          final s = nextEpisode['season_number'];
          final e = nextEpisode['episode_number'];
          final date = nextEpisode['air_date'];
          subtitleWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Next Episode:', style: theme.labelMedium),
              Text('S${s}E$e · $date', style: theme.bodyMedium),
            ],
          );
        } else if (lastEpisode != null) {
          final s = lastEpisode['season_number'];
          final e = lastEpisode['episode_number'];
          final date = lastEpisode['air_date'];
          subtitleWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Last Episode:', style: theme.labelMedium),
              Text('S${s}E$e · $date', style: theme.bodyMedium),
            ],
          );
        } else {
          subtitleWidget = Text('No upcoming episodes', style: theme.bodyMedium);
        }

        return MediaCard(
          title: seriesTitle,
          subtitleWidget: subtitleWidget,
          posterUrl: posterUrl,
          trailing: ActionMenu(onRemove: widget.onRemove),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SeriesDetailPage(seriesId: widget.seriesId),
              ),
            );
          },
        );
      },
    );
  }
}
