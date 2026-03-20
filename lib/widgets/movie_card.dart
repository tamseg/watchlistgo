import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/tmdb_service.dart';
import '../screens/movie_detail_page.dart';
import 'media_card.dart';

class MovieCard extends StatefulWidget {
  final int movieId;
  const MovieCard({required this.movieId, super.key});

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  late Future<Map<String, dynamic>?> _movieData;
  final TMDBService _tmdbService = TMDBService();

  @override
  void initState() {
    super.initState();
    _movieData = _tmdbService.getMovieDetails(widget.movieId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _movieData,
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
              title: const Text('Error loading movie'),
            ),
          );
        }

        final data = snapshot.data!;
        final movieTitle = data['title'] ?? 'Unknown Title';
        final posterPath = data['poster_path'];
        final posterUrl = posterPath != null
            ? 'https://image.tmdb.org/t/p/w200$posterPath'
            : null;

        final releaseDate = data['release_date'] ?? 'N/A';

        return MediaCard(
          title: movieTitle,
          subtitle: 'Released: $releaseDate',
          posterUrl: posterUrl,
          trailing: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Menu action coming soon
            },
          ),
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
