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
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(end: selected ? 1 : 0),
                duration: const Duration(milliseconds: 300),
                builder: (context, progress, child) => CustomPaint(
                  foregroundPainter: _UnderlinePainter(
                    progress: progress,
                    fromLeft: selected,
                  ),
                  child: child,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text.rich(text),
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

class _UnderlinePainter extends CustomPainter {
  final double progress;
  final bool fromLeft;

  const _UnderlinePainter({required this.progress, required this.fromLeft});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final width = size.width * progress;
    final left = fromLeft ? 0.0 : size.width - width;
    canvas.drawRRect(
      RRect.fromLTRBR(
        left,
        size.height - 2,
        left + width,
        size.height,
        const Radius.circular(1),
      ),
      Paint()..color = AppTheme.navActiveColor,
    );
  }

  @override
  bool shouldRepaint(_UnderlinePainter old) =>
      old.progress != progress || old.fromLeft != fromLeft;
}
