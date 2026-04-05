import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';
import '../services/tmdb_service.dart';
import '../widgets/logo_widget.dart';

class SeriesDetailPage extends StatefulWidget {
  final int seriesId;
  const SeriesDetailPage({required this.seriesId, super.key});

  @override
  State<SeriesDetailPage> createState() => _SeriesDetailPageState();
}

class _SeriesDetailPageState extends State<SeriesDetailPage> {
  late Future<Map<String, dynamic>?> _seriesData;
  late Future<Map<String, dynamic>?> _seriesImages;
  final TMDBService _tmdbService = TMDBService();

  @override
  void initState() {
    super.initState();
    _seriesData = _tmdbService.getDetails('tv', widget.seriesId);
    _seriesImages = _tmdbService.getImages('tv', widget.seriesId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: SvgPicture.asset(
            'assets/arrow_left.svg',
            width: 24,
            height: 24,
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: FutureBuilder<List<Map<String, dynamic>?>>(
        future: Future.wait([_seriesData, _seriesImages]),
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

          final title = data['name'] ?? 'Unknown';
          final overview = data['overview'] ?? 'No description available.';
          final backdropPath = data['backdrop_path'];
          final backdropUrl = backdropPath != null
              ? 'https://image.tmdb.org/t/p/original$backdropPath'
              : null;

          final logoPick = LogoWidget.pickLogo(imagesData);

          final rating = data['vote_average']?.toStringAsFixed(1) ?? 'N/A';
          final firstAirDate = data['first_air_date'] ?? 'N/A';
          final status = data['status'] ?? 'N/A';
          final seasons = data['number_of_seasons']?.toString() ?? 'N/A';
          final episodes = data['number_of_episodes']?.toString() ?? 'N/A';
          final genres =
              (data['genres'] as List?)?.map((g) => g['name']).join(', ') ??
              'N/A';

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBackdropHeader(backdropUrl, logoPick, title),
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 16),
                          Text('First Aired: $firstAirDate'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Status: $status | Seasons: $seasons ($episodes episodes)',
                        style: const TextStyle(
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildEpisodeBadge(data),
                      const SizedBox(height: 12),
                      Text(
                        'Genres: $genres',
                        style: const TextStyle(
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
                      const Divider(height: 32),
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
    (String url, bool isSvg)? logoPick,
    String title,
  ) {
    final maxLogoWidth =
        MediaQuery.of(context).size.width * AppTheme.detailLogoMaxWidthFactor;

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
            child: SizedBox(
              width: maxLogoWidth,
              height: AppTheme.detailLogoHeight,
              child: logoPick != null
                  ? LogoWidget(
                      logoUrl: logoPick.$1,
                      isSvg: logoPick.$2,
                      backdropUrl: backdropUrl,
                      fallbackTitle: title,
                      maxWidth: maxLogoWidth,
                      maxHeight: AppTheme.detailLogoHeight,
                    )
                  : Align(
                      alignment: Alignment.bottomLeft,
                      child: _buildTitleText(title),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleText(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppTheme.fallbackTitleColor,
      ),
    );
  }

  Widget _buildEpisodeBadge(Map<String, dynamic> data) {
    if (data['next_episode_to_air'] == null &&
        data['last_episode_to_air'] == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.episodeBadgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.episodeBadgeColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event, color: AppTheme.episodeBadgeColor, size: 18),
          const SizedBox(width: 8),
          Text(
            data['next_episode_to_air'] != null
                ? 'Next: S${data['next_episode_to_air']['season_number']}E${data['next_episode_to_air']['episode_number']} - ${data['next_episode_to_air']['air_date']}'
                : 'Last: S${data['last_episode_to_air']['season_number']}E${data['last_episode_to_air']['episode_number']} - ${data['last_episode_to_air']['air_date']}',
            style: const TextStyle(
              color: AppTheme.episodeBadgeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
