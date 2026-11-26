import 'package:material_ui/material_ui.dart';
import '../models/series_status.dart';
import '../services/series_info_service.dart';
import 'series_info_builder.dart';
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

  static const _spinner = Align(
    alignment: Alignment.centerLeft,
    child: SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );

  @override
  void initState() {
    super.initState();
    _seriesData = _tmdbService.getDetails('tv', widget.seriesId);
  }

  @override
  bool get wantKeepAlive => true;

  Widget _statusLines(StatusLine line, TextTheme theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        line.label,
        style: theme.labelMedium,
        overflow: TextOverflow.ellipsis,
      ),
      Text(
        line.value,
        style: theme.bodyMedium,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SeriesInfoBuilder(seriesId: widget.seriesId, builder: _buildCard);
  }

  Widget _buildCard(BuildContext context, SeriesInfoState infoState) {
    final info = infoState.info;
    return FutureBuilder<Map<String, dynamic>?>(
      future: _seriesData,
      initialData: _tmdbService.peekDetails('tv', widget.seriesId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
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
            trailing: ActionMenu(
              items: [ActionMenuItem.remove(widget.onRemove)],
            ),
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

        if (info != null) {
          subtitleWidget = _statusLines(
            seriesStatusLine(info, seriesTitle),
            theme,
          );
        } else if (infoState.status == SeriesInfoStatus.loading) {
          subtitleWidget = _spinner;
        } else if (nextEpisode != null) {
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
          subtitleWidget = Text(
            'No upcoming episodes',
            style: theme.bodyMedium,
          );
        }

        return MediaCard(
          title: seriesTitle,
          subtitleWidget: subtitleWidget,
          posterUrl: posterUrl,
          trailing: ActionMenu(items: [ActionMenuItem.remove(widget.onRemove)]),
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
