import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../services/tmdb_service.dart';

class MovieDetailPage extends StatefulWidget {
  final int movieId;
  const MovieDetailPage({required this.movieId, super.key});

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  late Future<Map<String, dynamic>?> _movieData;
  late Future<Map<String, dynamic>?> _movieImages;
  final TMDBService _tmdbService = TMDBService();

  @override
  void initState() {
    super.initState();
    _movieData = _tmdbService.getMovieDetails(widget.movieId);
    _movieImages = _tmdbService.getMovieImages(widget.movieId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading:
            Theme.of(context).platform != TargetPlatform.android,
        iconTheme: const IconThemeData(color: AppTheme.detailAppBarIconColor),
      ),
      extendBodyBehindAppBar: true,
      body: FutureBuilder<List<Map<String, dynamic>?>>(
        future: Future.wait([_movieData, _movieImages]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data![0] == null) {
            return const Center(child: Text('Error loading details'));
          }

          final data = snapshot.data![0]!;
          final imagesData = snapshot.data![1];

          final title = data['title'] ?? 'Unknown';
          final overview = data['overview'] ?? 'No description available.';
          final backdropPath = data['backdrop_path'];
          final backdropUrl = backdropPath != null
              ? 'https://image.tmdb.org/t/p/original$backdropPath'
              : null;

          String? logoUrl;
          if (imagesData != null && imagesData['logos'] != null) {
            final logos = imagesData['logos'] as List;
            final englishLogo = logos.firstWhere(
              (l) => l['iso_639_1'] == 'en',
              orElse: () => null,
            );
            if (englishLogo != null) {
              logoUrl =
                  'https://image.tmdb.org/t/p/w500${englishLogo['file_path']}';
            }
          }

          final rating = data['vote_average']?.toStringAsFixed(1) ?? 'N/A';
          final releaseDate = data['release_date'] ?? 'N/A';
          final runtime = data['runtime']?.toString() ?? 'N/A';
          final genres =
              (data['genres'] as List?)?.map((g) => g['name']).join(', ') ??
              'N/A';

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBackdropHeader(backdropUrl, logoUrl, title),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppTheme.ratingStarColor,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.calendar_today,
                            color: AppTheme.metaIconColor,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(releaseDate),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.timer,
                            color: AppTheme.metaIconColor,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text('$runtime min'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: genres.split(', ').map((genre) {
                          return Chip(
                            label: Text(genre),
                            labelStyle: const TextStyle(fontSize: 12),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        overview,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackdropHeader(
    String? backdropUrl,
    String? logoUrl,
    String title,
  ) {
    return SizedBox(
      height: AppTheme.backdropHeight,
      width: double.infinity,
      child: Stack(
        children: [
          if (backdropUrl != null)
            Container(
              height: AppTheme.backdropHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: CachedNetworkImageProvider(backdropUrl),
                  fit: BoxFit.cover,
                ),
              ),
              foregroundDecoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: AppTheme.backdropGradientColors,
                  stops: AppTheme.backdropGradientStops,
                ),
              ),
            )
          else
            Container(
              height: AppTheme.backdropHeight,
              color: AppTheme.placeholderColor,
              child: const Center(child: Icon(Icons.image, size: 50)),
            ),
          Positioned(
            left: 16,
            bottom: 16,
            child: logoUrl != null
                ? CachedNetworkImage(
                    imageUrl: logoUrl,
                    height: AppTheme.detailLogoHeight,
                    fit: BoxFit.contain,
                    placeholder: (context, url) =>
                        SizedBox(height: AppTheme.detailLogoHeight, width: 150),
                  )
                : Text(
                    title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.fallbackTitleColor,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
