import 'dart:math' as math;
import 'dart:ui';
import 'package:material_ui/material_ui.dart';
import '../theme/app_theme.dart';

class FloatingNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const FloatingNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

const double _barHeight = 56.0;
const double _bulgeHeight = 12.0;
const double _domeGap = 5.0;
const double _shoulderRadius = 26.0;
const double _sideMargin = 24.0;
const double _endInset = 64.0;
const double _bottomGap = 16.0;
const double _iconSize = 30.0;
const double _selectedIconScale = 1.5;
const double _indicatorSize = 58.0;
const Duration _slideDuration = Duration(milliseconds: 300);

const double _shapeHeight = _bulgeHeight + _barHeight;
const double _endRadius = _barHeight / 2;
const double _barCenterY = _bulgeHeight + _endRadius;
const double _domeRadius = _indicatorSize / 2 + _domeGap;
const double _selectedCenterY = _domeRadius;

final double _bulgeHalfWidth = math.sqrt(
  _bulgeHeight * (2 * (_domeRadius + _shoulderRadius) - _bulgeHeight),
);
final double _domeEdgeX =
    _bulgeHalfWidth * _domeRadius / (_domeRadius + _shoulderRadius);

double _bulgeLift(double dx) {
  final x = dx.abs();
  if (x >= _bulgeHalfWidth) return 0;
  if (x <= _domeEdgeX) {
    return _bulgeHeight -
        _domeRadius +
        math.sqrt(_domeRadius * _domeRadius - x * x);
  }
  final fromShoulder = x - _bulgeHalfWidth;
  return _shoulderRadius -
      math.sqrt(
        _shoulderRadius * _shoulderRadius - fromShoulder * fromShoulder,
      );
}

class FloatingNavBar extends StatelessWidget {
  final List<FloatingNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;

    return SizedBox(
      height: _shapeHeight + _bottomGap + safeBottom,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth - 2 * _sideMargin;
          final n = items.length;
          const firstCenter = _endInset;
          final spacing = n > 1 ? (barWidth - 2 * firstCenter) / (n - 1) : 0.0;
          double centerOf(int i) =>
              n > 1 ? firstCenter + spacing * i : barWidth / 2;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              if (n == 1) return onTap(0);
              final x = details.localPosition.dx - _sideMargin - firstCenter;
              onTap((x / spacing).round().clamp(0, n - 1));
            },
            child: Stack(
              children: [
                Positioned(
                  left: _sideMargin,
                  right: _sideMargin,
                  top: 0,
                  height: _shapeHeight,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: centerOf(currentIndex)),
                    duration: _slideDuration,
                    curve: Curves.easeInOut,
                    builder: (context, bulgeX, _) {
                      final shape = _BulgeShape(bulgeX);
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(painter: _ShadowPainter(shape)),
                          ),
                          Positioned.fill(
                            child: ClipPath(
                              clipper: shape,
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: AppTheme.glassBlurSigma,
                                  sigmaY: AppTheme.glassBlurSigma,
                                ),
                                child: ColoredBox(
                                  color: Colors.white.withValues(
                                    alpha: AppTheme.glassOpacity,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: CustomPaint(painter: _OutlinePainter(shape)),
                          ),
                          Positioned(
                            left: bulgeX - _indicatorSize / 2,
                            top: _selectedCenterY - _indicatorSize / 2,
                            width: _indicatorSize,
                            height: _indicatorSize,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppTheme.navActiveColor.withValues(
                                  alpha: 0.12,
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                for (var i = 0; i < n; i++)
                  Positioned(
                    left: _sideMargin + centerOf(i) - _iconSize / 2,
                    top: _barCenterY - _iconSize / 2,
                    width: _iconSize,
                    height: _iconSize,
                    child: _NavIcon(
                      item: items[i],
                      selected: i == currentIndex,
                      onTap: () => onTap(i),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BulgeShape extends CustomClipper<Path> {
  final double bulgeX;

  const _BulgeShape(this.bulgeX);

  @override
  Path getClip(Size size) {
    final w = size.width;

    Offset raised(double x, double y) {
      if (y >= _barCenterY) return Offset(x, y);
      final weight = ((_barCenterY - y) / _endRadius).clamp(0.0, 1.0);
      return Offset(x, y - _bulgeLift(x - bulgeX) * weight);
    }

    Offset onEnd(double cx, double angle) => Offset(
      cx + _endRadius * math.cos(angle),
      _barCenterY + _endRadius * math.sin(angle),
    );

    final points = <Offset>[];
    for (var deg = 90.0; deg <= 270.0; deg += 2) {
      final p = onEnd(_endRadius, deg * math.pi / 180);
      points.add(raised(p.dx, p.dy));
    }
    for (var x = _endRadius + 1; x < w - _endRadius; x += 1) {
      points.add(raised(x, _bulgeHeight));
    }
    for (var deg = -90.0; deg <= 90.0; deg += 2) {
      final p = onEnd(w - _endRadius, deg * math.pi / 180);
      points.add(raised(p.dx, p.dy));
    }

    return Path()..addPolygon(points, true);
  }

  @override
  bool shouldReclip(_BulgeShape oldClipper) => oldClipper.bulgeX != bulgeX;
}

class _ShadowPainter extends CustomPainter {
  final _BulgeShape shape;

  const _ShadowPainter(this.shape);

  @override
  void paint(Canvas canvas, Size size) {
    final path = shape.getClip(size);
    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect((Offset.zero & size).inflate(32)),
      path,
    );
    canvas
      ..save()
      ..clipPath(outside)
      ..drawPath(
        path.shift(const Offset(0, 4)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_ShadowPainter oldDelegate) =>
      oldDelegate.shape.bulgeX != shape.bulgeX;
}

class _OutlinePainter extends CustomPainter {
  final _BulgeShape shape;

  const _OutlinePainter(this.shape);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      shape.getClip(size),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black.withValues(alpha: 0.06),
    );
  }

  @override
  bool shouldRepaint(_OutlinePainter oldDelegate) =>
      oldDelegate.shape.bulgeX != shape.bulgeX;
}

class _NavIcon extends StatelessWidget {
  final FloatingNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavIcon({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      onTap: onTap,
      excludeSemantics: true,
      child: AnimatedSlide(
        offset: selected
            ? const Offset(0, (_selectedCenterY - _barCenterY) / _iconSize)
            : Offset.zero,
        duration: _slideDuration,
        curve: Curves.easeInOut,
        child: AnimatedScale(
          scale: selected ? _selectedIconScale : 1.0,
          duration: _slideDuration,
          curve: Curves.easeInOut,
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(
              end: selected ? AppTheme.navActiveColor : AppTheme.metaIconColor,
            ),
            duration: _slideDuration,
            curve: Curves.easeInOut,
            builder: (context, color, _) => Icon(
              selected ? item.activeIcon : item.icon,
              size: _iconSize,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
