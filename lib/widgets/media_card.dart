import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import 'scrolling_text.dart';

class MediaCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? posterUrl;
  final Widget? subtitleWidget;
  final Widget? trailing;
  final VoidCallback? onTap;

  const MediaCard({
    required this.title,
    this.subtitle,
    this.posterUrl,
    this.subtitleWidget,
    this.trailing,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        minTileHeight: AppTheme.cardHeight,
        leading: posterUrl != null
            ? SizedBox(
                width: 44,
                height: 66,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6.0),
                  child: CachedNetworkImage(
                    imageUrl: posterUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: AppTheme.placeholderColor),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.movie),
                  ),
                ),
              )
            : const Icon(Icons.movie),
        title: ScrollingText(text: title),
        subtitle:
            subtitleWidget ??
            (subtitle != null ? ScrollingText(text: subtitle!) : null),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
