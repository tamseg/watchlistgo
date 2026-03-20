import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/tmdb_service.dart';
import '../screens/series_detail_page.dart';
import 'media_card.dart';
import 'action_menu.dart';

class SeriesCard extends StatefulWidget {
  final int seriesId;
  final VoidCallback onRemove;

  const SeriesCard({
    required this.seriesId,
    required this.onRemove,
    super.key,
  });

  @override
  State<SeriesCard> createState() => _SeriesCardState();
}

class _SeriesCardState extends State<SeriesCard> {
  late Future<Map<String, dynamic>?> _seriesData;
  final TMDBService _tmdbService = TMDBService();

  @override
  void initState() {
    super.initState();
    _seriesData = _tmdbService.getTVDetails(widget.seriesId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _seriesData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            child: ListTile(
              minTileHeight: AppTheme.cardHeight,
              leading: const CircularProgressIndicator(),
              title: const Text('Loading...'),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Card(
            child: ListTile(
              minTileHeight: AppTheme.cardHeight,
              leading: const Icon(Icons.error),
              title: const Text('Error loading series'),
            ),
          );
        }

        final data = snapshot.data!;
        final seriesTitle = data['name'] ?? 'Unknown Title';
        final posterPath = data['poster_path'];
        final posterUrl = posterPath != null
            ? 'https://image.tmdb.org/t/p/w200$posterPath'
            : null;

        String episodeInfo = 'No upcoming episodes';
        final nextEpisode = data['next_episode_to_air'];
        final lastEpisode = data['last_episode_to_air'];

        if (nextEpisode != null) {
          final s = nextEpisode['season_number'];
          final e = nextEpisode['episode_number'];
          final date = nextEpisode['air_date'];
          episodeInfo = 'Next: S${s}E$e - $date';
        } else if (lastEpisode != null) {
          final s = lastEpisode['season_number'];
          final e = lastEpisode['episode_number'];
          final date = lastEpisode['air_date'];
          episodeInfo = 'Last: S${s}E$e - $date';
        }

        return MediaCard(
          title: seriesTitle,
          subtitle: episodeInfo,
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
