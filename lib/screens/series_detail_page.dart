import 'package:material_ui/material_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';
import '../models/series_status.dart';
import '../services/series_info_service.dart';
import '../services/tmdb_service.dart';
import '../widgets/logo_widget.dart';
import '../widgets/series_info_builder.dart';

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
    final statusBarHeight = MediaQuery.viewPaddingOf(context).top;

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
      body: Padding(
        padding: EdgeInsets.only(top: statusBarHeight),
        child: FutureBuilder<List<Map<String, dynamic>?>>(
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text('First Aired: $firstAirDate'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SeriesInfoBuilder(
                          seriesId: widget.seriesId,
                          builder: (context, info) => _buildStatus(data, info),
                        ),
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

  Widget _buildStatus(Map<String, dynamic> data, SeriesInfoState state) {
    if (state.status == SeriesInfoStatus.loading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    final info = state.info;
    final String summary;
    final List<String> badges;
    if (info != null) {
      final name = data['name'] as String? ?? '';
      final line = seriesStatusLine(info, name, detailed: true);
      final film = filmLine(info, name);
      summary =
          'Status: ${seriesStateName(info.state)} | '
          'Seasons: ${info.releasedSeasons} '
          '(${info.releasedEpisodes} episodes)';
      badges = [
        for (final l in {line, ?film}) '${l.label} · ${l.value}',
      ];
    } else {
      summary =
          'Status: ${data['status'] ?? 'N/A'} | '
          'Seasons: ${data['number_of_seasons'] ?? 'N/A'} '
          '(${data['number_of_episodes'] ?? 'N/A'} episodes)';
      final badge = _tmdbEpisodeText(data);
      badges = [?badge];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          summary,
          style: const TextStyle(color: AppTheme.secondaryTextColor),
        ),
        for (final text in badges) ...[
          const SizedBox(height: 8),
          _buildBadge(text),
        ],
      ],
    );
  }

  String? _tmdbEpisodeText(Map<String, dynamic> data) {
    final next = data['next_episode_to_air'];
    final last = data['last_episode_to_air'];
    final episode = next ?? last;
    if (episode == null) return null;
    final code = 'S${episode['season_number']}E${episode['episode_number']}';
    return '${next != null ? 'Next' : 'Last'}: $code - ${episode['air_date']}';
  }

  Widget _buildBadge(String text) {
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
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.episodeBadgeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
