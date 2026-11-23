import 'package:material_ui/material_ui.dart';

class ScrollingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration pauseDuration;

  const ScrollingText({
    super.key,
    required this.text,
    this.style,
    this.pauseDuration = const Duration(seconds: 2),
  });

  @override
  State<ScrollingText> createState() => _ScrollingTextState();
}

class _ScrollingTextState extends State<ScrollingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(ScrollingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _isPlaying = false;
      _animationController.stop();
      _animationController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startAnimation(double maxExtent) async {
    if (_isPlaying || maxExtent < 1.0) return;
    _isPlaying = true;

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted || !_isPlaying) return;

    int ms = (maxExtent * 1000 / 25).toInt();
    if (ms < 100) ms = 100;
    final duration = Duration(milliseconds: ms);

    _animationController.duration = duration;

    while (mounted && _isPlaying) {
      await _animationController.forward();
      if (!mounted || !_isPlaying) break;

      await Future.delayed(widget.pauseDuration);
      if (!mounted || !_isPlaying) break;

      await _animationController.reverse();
      if (!mounted || !_isPlaying) break;

      await Future.delayed(widget.pauseDuration);
    }
  }

  void _stopAnimation() {
    _isPlaying = false;
    _animationController.stop();
    _animationController.animateBack(
      0.0,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);
    TextStyle? effectiveStyle = widget.style;
    if (effectiveStyle == null || effectiveStyle.inherit) {
      effectiveStyle = defaultTextStyle.style.merge(widget.style);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: effectiveStyle),
          maxLines: 1,
          textDirection: Directionality.of(context),
        );
        textPainter.layout(minWidth: 0, maxWidth: double.infinity);

        if (textPainter.width > constraints.maxWidth &&
            constraints.maxWidth > 0) {
          final double overflowWidth = textPainter.width - constraints.maxWidth;

          final Widget content = SizedBox(
            width: constraints.maxWidth,
            child: ClipRect(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final double val = _animationController.value.isNaN
                      ? 0.0
                      : _animationController.value;
                  final double scroll = val * overflowWidth;

                  const double fadeWidth = 16.0;
                  final double leftEdgeAlpha =
                      1.0 - (scroll / fadeWidth).clamp(0.0, 1.0);
                  final double rightEdgeAlpha =
                      1.0 -
                      ((overflowWidth - scroll) / fadeWidth).clamp(0.0, 1.0);

                  final Color leftColor = Colors.white.withAlpha(
                    (leftEdgeAlpha * 255).toInt(),
                  );
                  final Color rightColor = Colors.white.withAlpha(
                    (rightEdgeAlpha * 255).toInt(),
                  );

                  return ShaderMask(
                    shaderCallback: (Rect bounds) {
                      final double startStop = fadeWidth / bounds.width;
                      final double endStop = 1.0 - (fadeWidth / bounds.width);
                      return LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          leftColor,
                          Colors.white,
                          Colors.white,
                          rightColor,
                        ],
                        stops: [0.0, startStop, endStop, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: Transform.translate(
                      offset: Offset(-scroll, 0),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  widget.text,
                  style: widget.style,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
          );

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPressDown: (_) {
              if (!_isPlaying) _startAnimation(overflowWidth);
            },
            onLongPressCancel: () => _stopAnimation(),
            onLongPressUp: () => _stopAnimation(),
            child: content,
          );
        } else {
          _isPlaying = false;
          _animationController.stop();
          _animationController.value = 0.0;

          return Text(
            widget.text,
            style: widget.style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }
      },
    );
  }
}
