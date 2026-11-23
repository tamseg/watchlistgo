import 'package:material_ui/material_ui.dart';
import '../theme/app_theme.dart';

const double _expandedHeaderHeight = 92.0;
const double _collapsedBarHeight = 44.0;
const double _expandedTitleSize = 34.0;
const double _collapsedTitleSize = 18.0;
const double _titleBottomPadding = 11.0;

class WatchlistPage extends StatelessWidget {
  final String title;
  final List<int> ids;
  final IconData emptyIcon;
  final String emptyLabel;
  final Widget Function(int id) itemBuilder;

  const WatchlistPage({
    required this.title,
    required this.ids,
    required this.emptyIcon,
    required this.emptyLabel,
    required this.itemBuilder,
    super.key,
  });

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            emptyIcon,
            size: 64,
            color: AppTheme.metaIconColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Your $emptyLabel watchlist is empty.',
            style: const TextStyle(color: AppTheme.metaIconColor, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Go to Search to find your favorites!',
            style: TextStyle(color: AppTheme.metaIconColor, fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: pageColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            primary: false,
            pinned: true,
            expandedHeight: _expandedHeaderHeight,
            toolbarHeight: _collapsedBarHeight,
            automaticallyImplyLeading: false,
            backgroundColor: pageColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsetsDirectional.only(
                start: 26.0,
                bottom: _titleBottomPadding,
              ),
              expandedTitleScale: _expandedTitleSize / _collapsedTitleSize,
              title: Text(
                title,
                style: const TextStyle(
                  fontSize: _collapsedTitleSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (ids.isEmpty)
            SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14.0, 8.0, 14.0, 64.0),
              sliver: SliverList.list(children: ids.map(itemBuilder).toList()),
            ),
        ],
      ),
    );
  }
}
