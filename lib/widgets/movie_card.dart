import 'package:material_ui/material_ui.dart';
import '../services/tmdb_service.dart';
import '../screens/movie_detail_page.dart';
import 'media_card.dart';
import 'action_menu.dart';

class MovieCard extends StatefulWidget {
  final int movieId;
  final VoidCallback onRemove;

  const MovieCard({required this.movieId, required this.onRemove, super.key});

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard>
    with AutomaticKeepAliveClientMixin {
  late Future<Map<String, dynamic>?> _movieData;
  final TMDBService _tmdbService = TMDBService();

  @override
  void initState() {
    super.initState();
    _movieData = _tmdbService.getDetails('movie', widget.movieId);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<Map<String, dynamic>?>(
      future: _movieData,
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
            title: 'Error loading movie',
            subtitle: 'Tap to retry',
            trailing: ActionMenu(onRemove: widget.onRemove),
          );
        }

        final data = snapshot.data!;
        final movieTitle = data['title'] ?? 'Unknown Title';
        final posterPath = data['poster_path'];
        final posterUrl = posterPath != null
            ? 'https://image.tmdb.org/t/p/w200$posterPath'
            : null;

        final releaseDate = data['release_date'] ?? 'N/A';
        final theme = Theme.of(context).textTheme;

        final subtitleWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Released:', style: theme.labelMedium),
            Text(releaseDate, style: theme.bodyMedium),
          ],
        );

        return MediaCard(
          title: movieTitle,
          subtitleWidget: subtitleWidget,
          posterUrl: posterUrl,
          trailing: ActionMenu(onRemove: widget.onRemove),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MovieDetailPage(movieId: widget.movieId),
              ),
            );
          },
        );
      },
    );
  }
}
