import 'dart:async';
import 'package:material_ui/material_ui.dart';
import '../theme/app_theme.dart';
import '../services/tmdb_service.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/media_card.dart';

class SearchPage extends StatefulWidget {
  final List<int> followedSeriesIds;
  final List<int> followedMoviesIds;
  final void Function(int id) onAddSeries;
  final void Function(int id) onAddMovie;

  const SearchPage({
    required this.followedSeriesIds,
    required this.followedMoviesIds,
    required this.onAddSeries,
    required this.onAddMovie,
    super.key,
  });

  @override
  State<SearchPage> createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void requestSearchFocus() {
    _searchFocusNode.requestFocus();
  }

  void unfocusSearch() {
    _searchFocusNode.unfocus();
  }

  final TMDBService _tmdbService = TMDBService();
  Timer? _debounceTimer;
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();

    if (query.trim().length < 3) {
      setState(() {
        _results = [];
        _hasSearched = false;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    final results = await _tmdbService.searchMulti(query);
    if (mounted) {
      setState(() {
        _results = results;
        _isLoading = false;
        _hasSearched = true;
      });
    }
  }

  bool _isAlreadyAdded(Map<String, dynamic> item) {
    final id = item['id'] as int;
    final mediaType = item['media_type'] as String;
    if (mediaType == 'tv') {
      return widget.followedSeriesIds.contains(id);
    } else {
      return widget.followedMoviesIds.contains(id);
    }
  }

  void _addItem(Map<String, dynamic> item) {
    final id = item['id'] as int;
    final mediaType = item['media_type'] as String;
    final title = mediaType == 'tv'
        ? (item['name'] ?? 'Unknown')
        : (item['title'] ?? 'Unknown');
    final typeLabel = mediaType == 'tv' ? 'Series' : 'Movies';

    if (mediaType == 'tv') {
      widget.onAddSeries(id);
    } else {
      widget.onAddMovie(id);
    }

    setState(() {});

    showCustomSnackBar(context, 'Added "$title" to $typeLabel');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(84),
          child: Padding(
            padding: const EdgeInsets.only(
              left: 18.0,
              right: 18.0,
              bottom: 12.0,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                border: !_searchFocusNode.hasFocus
                    ? Border.all(
                        color: Colors.grey.withValues(alpha: 0.3),
                        width: 1.0,
                      )
                    : null,
                gradient: _searchFocusNode.hasFocus
                    ? const LinearGradient(
                        begin: Alignment(-0.2, -1.5),
                        end: Alignment(0.2, 1.5),
                        colors: [
                          Color(0xFF5edde0),
                          Color(0xFF538feb),
                          Color(0xFF7f73ea),
                        ],
                        stops: [0.4, 0.8, 1.0],
                        transform: GradientRotation(0.4),
                      )
                    : null,
                boxShadow: [
                  if (_searchFocusNode.hasFocus)
                    BoxShadow(
                      color: const Color(0xFF538feb).withValues(alpha: 0.25),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                ],
              ),
              padding: EdgeInsets.all(_searchFocusNode.hasFocus ? 1.5 : 0),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search movies & series...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Search for movies & series\nto add to your watchlist',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(
        left: 14.0,
        right: 14.0,
        top: 130.0,
        bottom: 64.0,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final item = _results[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: _SearchResultCard(
            item: item,
            isAdded: _isAlreadyAdded(item),
            onAdd: () => _addItem(item),
          ),
        );
      },
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isAdded;
  final VoidCallback onAdd;

  const _SearchResultCard({
    required this.item,
    required this.isAdded,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final mediaType = item['media_type'] as String;
    final title = mediaType == 'tv'
        ? (item['name'] ?? 'Unknown Title')
        : (item['title'] ?? 'Unknown Title');
    final posterPath = item['poster_path'];
    final posterUrl = posterPath != null
        ? 'https://image.tmdb.org/t/p/w200$posterPath'
        : null;

    final dateStr = mediaType == 'tv'
        ? item['first_air_date']
        : item['release_date'];
    final year = (dateStr != null && dateStr.toString().length >= 4)
        ? dateStr.toString().substring(0, 4)
        : 'N/A';

    final rating = item['vote_average'];
    final ratingStr = rating != null ? rating.toStringAsFixed(1) : 'N/A';

    final typeLabel = mediaType == 'tv' ? 'Series' : 'Movie';

    return MediaCard(
      title: title,
      posterUrl: posterUrl,
      subtitleWidget: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: mediaType == 'tv'
                  ? AppTheme.episodeBadgeColor.withValues(alpha: 0.15)
                  : AppTheme.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              typeLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: mediaType == 'tv'
                    ? AppTheme.episodeBadgeColor
                    : AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            year,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.secondaryTextColor,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.star, size: 14, color: AppTheme.ratingStarColor),
          const SizedBox(width: 2),
          Text(
            ratingStr,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.secondaryTextColor,
            ),
          ),
        ],
      ),
      trailing: isAdded
          ? TextButton.icon(
              onPressed: null,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Added'),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
            )
          : TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
    );
  }
}
