import 'package:material_ui/material_ui.dart';
import '../theme/app_theme.dart';

const double viewSelectorHeight = 40.0;

class ViewSelector extends StatelessWidget {
  final List<String> labels;
  final List<int> counts;
  final int selected;
  final ValueChanged<int> onSelected;

  const ViewSelector({
    super.key,
    required this.labels,
    required this.counts,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: viewSelectorHeight,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            _ViewTab(
              label: labels[i],
              count: counts[i],
              selected: i == selected,
              onTap: () => onSelected(i),
            ),
        ],
      ),
    );
  }
}

class _ViewTab extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _ViewTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.darkTextColor : AppTheme.metaIconColor;
    final text = TextSpan(
      children: [
        TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
        TextSpan(
          text: '  $count',
          style: const TextStyle(fontSize: 13, color: AppTheme.metaIconColor),
        ),
      ],
    );
    final textWidth = (TextPainter(
      text: text,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout()).width;

    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $count',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(right: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(text),
              const SizedBox(height: 2),
              SizedBox(
                width: textWidth,
                child: Align(
                  alignment: selected
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 2,
                    width: selected ? textWidth : 0,
                    decoration: BoxDecoration(
                      color: AppTheme.navActiveColor,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}
