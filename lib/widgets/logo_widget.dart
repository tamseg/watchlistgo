import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:palette_generator/palette_generator.dart';
import '../theme/app_theme.dart';

class LogoWidget extends StatefulWidget {
  final String logoUrl;
  final bool isSvg;
  final String? backdropUrl;
  final String fallbackTitle;
  final double maxWidth;
  final double maxHeight;

  const LogoWidget({
    super.key,
    required this.logoUrl,
    required this.isSvg,
    required this.backdropUrl,
    required this.fallbackTitle,
    required this.maxWidth,
    required this.maxHeight,
  });

  static (String url, bool isSvg)? pickLogo(Map<String, dynamic>? imagesData) {
    if (imagesData == null || imagesData['logos'] == null) return null;
    final logos = List<Map<String, dynamic>>.from(imagesData['logos'] as List);
    if (logos.isEmpty) return null;

    logos.sort((a, b) {
      final aEn = a['iso_639_1'] == 'en' ? 0 : 1;
      final bEn = b['iso_639_1'] == 'en' ? 0 : 1;
      if (aEn != bEn) return aEn.compareTo(bEn);
      return ((b['vote_average'] ?? 0) as num)
          .compareTo((a['vote_average'] ?? 0) as num);
    });

    Map<String, dynamic>? pick;
    for (final logo in logos) {
      final path = logo['file_path'] as String? ?? '';
      if (!path.toLowerCase().endsWith('.svg')) {
        pick = logo;
        break;
      }
    }
    pick ??= logos.first;

    final path = pick['file_path'] as String;
    final isSvg = path.toLowerCase().endsWith('.svg');
    final size = isSvg ? 'original' : 'w500';
    final url = 'https://image.tmdb.org/t/p/$size$path';
    return (url, isSvg);
  }

  @override
  State<LogoWidget> createState() => _LogoWidgetState();
}

class _LogoWidgetState extends State<LogoWidget> {
  static final _svgCache = <String, String>{};

  static final _fillHexAttr = RegExp(r'fill="#([0-9a-fA-F]{3,6})"');
  static final _fillHexStyle = RegExp(r'fill\s*:\s*#([0-9a-fA-F]{3,6})');
  static final _fillBlack = RegExp(r'fill="black"', caseSensitive: false);
  static final _fillWhite = RegExp(r'fill="white"', caseSensitive: false);

  ColorFilter? _svgTint;
  bool _tintResolved = false;
  String? _svgData;

  @override
  void initState() {
    super.initState();
    if (widget.backdropUrl != null) {
      _analyseBackdropContrast();
    } else {
      _tintResolved = true;
    }
  }

  Future<void> _analyseBackdropContrast() async {
    try {
      Color logoColor = Colors.black;
      bool isMonochrome = true;

      if (widget.isSvg) {
        final cached = _svgCache[widget.logoUrl];
        if (cached != null) {
          _svgData = cached;
        } else {
          final svgResponse = await http.get(Uri.parse(widget.logoUrl));
          if (svgResponse.statusCode == 200) {
            _svgData = svgResponse.body;
            _svgCache[widget.logoUrl] = _svgData!;
          }
        }

        if (_svgData != null) {
          final svgColors = _extractSvgColors(_svgData!);
          logoColor = svgColors.first;
          if (svgColors.length > 1) {
            for (final c in svgColors.skip(1)) {
              if (_contrastRatio(svgColors.first, c) > 1.3) {
                isMonochrome = false;
                break;
              }
            }
          }
        }
      } else {
        try {
          final logoPalette = await PaletteGenerator.fromImageProvider(
            CachedNetworkImageProvider(widget.logoUrl),
            size: const Size(100, 50),
          );
          logoColor = logoPalette.dominantColor?.color ?? Colors.black;
          if (logoPalette.paletteColors.length > 3) {
            final total = logoPalette.paletteColors.fold(
              0, (sum, c) => sum + c.population,
            );
            final dominantPop = logoPalette.dominantColor?.population ?? 0;
            if (dominantPop / total < 0.5) {
              isMonochrome = false;
            }
          }
        } catch (_) {}
      }

      if (!isMonochrome) {
        if (mounted) setState(() => _tintResolved = true);
        return;
      }

      final backdropColor = await _sampleBackdropBehindLogo();
      final ratio = _contrastRatio(logoColor, backdropColor);

      if (mounted) {
        setState(() {
          if (ratio < 1.5) {
            final bgLum = backdropColor.computeLuminance();
            _svgTint = bgLum < 0.5
                ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                : ColorFilter.mode(Colors.grey[900]!, BlendMode.srcIn);
          }
          _tintResolved = true;
        });
      }
    } catch (e) {
      debugPrint('[LOGO] Contrast analysis failed: $e');
      if (mounted) setState(() => _tintResolved = true);
    }
  }

  Future<Color> _sampleBackdropBehindLogo() async {
    final smallUrl =
        widget.backdropUrl!.replaceFirst('/original/', '/w780/');
    final provider = CachedNetworkImageProvider(smallUrl);
    final stream = provider.resolve(const ImageConfiguration());
    final completer = Completer<ImageInfo>();
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (!completer.isCompleted) completer.complete(info);
        stream.removeListener(listener);
      },
      onError: (error, _) {
        if (!completer.isCompleted) completer.completeError(error);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    final imageInfo = await completer.future;
    final imgW = imageInfo.image.width.toDouble();
    final imgH = imageInfo.image.height.toDouble();
    imageInfo.dispose();

    if (!mounted) return Colors.grey;
    final screenWidth = MediaQuery.of(context).size.width;
    const logoLeft = 16.0;
    const logoBottom = 16.0;
    final logoTop = (AppTheme.backdropHeight - logoBottom - widget.maxHeight)
        .clamp(0.0, AppTheme.backdropHeight);

    final xFrac = logoLeft / screenWidth;
    final yFrac = logoTop / AppTheme.backdropHeight;
    final wFrac = widget.maxWidth / screenWidth;
    final hFrac = widget.maxHeight / AppTheme.backdropHeight;

    final region = Rect.fromLTWH(
      imgW * xFrac,
      imgH * yFrac,
      (imgW * wFrac).clamp(1, imgW - imgW * xFrac),
      (imgH * hFrac).clamp(1, imgH - imgH * yFrac),
    );

    final palette = await PaletteGenerator.fromImageProvider(
      provider,
      size: Size(imgW, imgH),
      region: region,
    );

    return palette.dominantColor?.color ?? Colors.grey;
  }

  List<Color> _extractSvgColors(String svgXml) {
    final seen = <int>{};
    final colors = <Color>[];

    void addIfNew(Color c) {
      if (seen.add(c.toARGB32())) colors.add(c);
    }

    for (final m in _fillHexAttr.allMatches(svgXml)) {
      final c = _hexToColor(m.group(1)!);
      if (c != null) addIfNew(c);
    }
    for (final m in _fillHexStyle.allMatches(svgXml)) {
      final c = _hexToColor(m.group(1)!);
      if (c != null) addIfNew(c);
    }
    if (_fillBlack.hasMatch(svgXml)) {
      addIfNew(Colors.black);
    }
    if (_fillWhite.hasMatch(svgXml)) {
      addIfNew(Colors.white);
    }

    if (colors.isEmpty) return [Colors.black];
    return colors;
  }

  Color? _hexToColor(String hex) {
    if (hex.length == 3) {
      hex = '${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}';
    }
    final value = int.tryParse('FF$hex', radix: 16);
    return value != null ? Color(value) : null;
  }

  double _contrastRatio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final light = la > lb ? la : lb;
    final dark = la > lb ? lb : la;
    return (light + 0.05) / (dark + 0.05);
  }

  @override
  Widget build(BuildContext context) {
    if (!_tintResolved) {
      return SizedBox(
        width: widget.maxWidth,
        height: widget.maxHeight,
      );
    }

    if (widget.isSvg) {
      if (_svgData != null) {
        return SvgPicture.string(
          _svgData!,
          fit: BoxFit.contain,
          alignment: Alignment.bottomLeft,
          width: widget.maxWidth,
          height: widget.maxHeight,
          colorFilter: _svgTint,
          placeholderBuilder: (_) => SizedBox(
            width: widget.maxWidth,
            height: widget.maxHeight,
          ),
        );
      }
      return SvgPicture.network(
        widget.logoUrl,
        fit: BoxFit.contain,
        alignment: Alignment.bottomLeft,
        width: widget.maxWidth,
        height: widget.maxHeight,
        colorFilter: _svgTint,
        placeholderBuilder: (_) => SizedBox(
          width: widget.maxWidth,
          height: widget.maxHeight,
        ),
      );
    }

    Widget image = CachedNetworkImage(
      imageUrl: widget.logoUrl,
      fit: BoxFit.contain,
      alignment: Alignment.bottomLeft,
      placeholder: (_, __) => const SizedBox.shrink(),
      errorWidget: (_, __, ___) => Align(
        alignment: Alignment.bottomLeft,
        child: Text(
          widget.fallbackTitle,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.fallbackTitleColor,
          ),
        ),
      ),
    );

    if (_svgTint != null) {
      image = ColorFiltered(colorFilter: _svgTint!, child: image);
    }

    return SizedBox(
      width: widget.maxWidth,
      height: widget.maxHeight,
      child: image,
    );
  }
}
