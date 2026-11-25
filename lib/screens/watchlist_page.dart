import 'package:material_ui/material_ui.dart';
import '../theme/app_theme.dart';
import '../widgets/view_selector.dart';

const double _expandedHeaderHeight = 92.0;
const double _collapsedBarHeight = 44.0;
const double _expandedTitleSize = 34.0;
const double _collapsedTitleSize = 18.0;
const double _titleBottomPadding = 11.0;
const double _contentInset = 26.0;

class WatchlistView<T> {
  final String label;
  final bool Function(T item) includes;
  final String emptyMessage;

  const WatchlistView({
    required this.label,
    required this.includes,
    required this.emptyMessage,
  });
}

class WatchlistPage<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final IconData emptyIcon;
  final String emptyLabel;
  final Widget Function(T item) itemBuilder;
  final List<WatchlistView<T>> views;

  const WatchlistPage({
    required this.title,
    required this.items,
    required this.emptyIcon,
    required this.emptyLabel,
    required this.itemBuilder,
    this.views = const [],
    super.key,
  });

  @override
  State<WatchlistPage<T>> createState() => _WatchlistPageState<T>();
}

class _WatchlistPageState<T> extends State<WatchlistPage<T>> {
  int _selectedView = 0;

  WatchlistView<T>? get _view =>
      widget.views.isEmpty ? null : widget.views[_selectedView];

  Widget _buildEmptyState(List<String> lines) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.emptyIcon,
            size: 64,
            color: AppTheme.metaIconColor.withValues(alpha: 0.5),
          ),
          for (final line in lines) ...[
            const SizedBox(height: 8),
            Text(
              line,
              style: const TextStyle(
                color: AppTheme.metaIconColor,
                fontSize: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageColor = Theme.of(context).scaffoldBackgroundColor;
    final view = _view;
    final visible = view == null
        ? widget.items
        : widget.items.where(view.includes).toList();
    final selectorHeight = view == null ? 0.0 : viewSelectorHeight;

    final Widget content;
    if (widget.items.isEmpty) {
      content = SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState([
          'Your ${widget.emptyLabel} watchlist is empty.',
          'Go to Search to find your favorites!',
        ]),
      );
    } else if (visible.isEmpty) {
      content = SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState([view!.emptyMessage]),
      );
    } else {
      content = SliverPadding(
        padding: EdgeInsets.fromLTRB(
          14.0,
          8.0,
          14.0,
          MediaQuery.paddingOf(context).bottom + 16.0,
        ),
        sliver: SliverList.list(
          children: visible.map(widget.itemBuilder).toList(),
        ),
      );
    }

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
            expandedHeight: _expandedHeaderHeight + selectorHeight,
            toolbarHeight: _collapsedBarHeight,
            automaticallyImplyLeading: false,
            backgroundColor: pageColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: EdgeInsetsDirectional.only(
                start: _contentInset,
                bottom: _titleBottomPadding + selectorHeight,
              ),
              expandedTitleScale: _expandedTitleSize / _collapsedTitleSize,
              title: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: _collapsedTitleSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            bottom: view == null
                ? null
                : PreferredSize(
                    preferredSize: const Size.fromHeight(viewSelectorHeight),
                    child: Padding(
                      padding: const EdgeInsets.only(left: _contentInset),
                      child: ViewSelector(
                        labels: [for (final v in widget.views) v.label],
                        counts: [
                          for (final v in widget.views)
                            widget.items.where(v.includes).length,
                        ],
                        selected: _selectedView,
                        onSelected: (i) => setState(() => _selectedView = i),
                      ),
                    ),
                  ),
          ),
          content,
        ],
      ),
    );
  }
}
