import 'package:material_ui/material_ui.dart';
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
    return Container(
      constraints: const BoxConstraints(
        minHeight: AppTheme.cardHeight,
        maxHeight: AppTheme.cardHeight,
      ),
      decoration: AppTheme.cardDecoration,
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  height: 78,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: posterUrl != null
                        ? CachedNetworkImage(
                            imageUrl: posterUrl!,
                            fit: BoxFit.cover,
                            fadeInDuration: Duration.zero,
                            fadeOutDuration: Duration.zero,
                            placeholder: (context, url) =>
                                Container(color: AppTheme.placeholderColor),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.movie),
                          )
                        : const Icon(Icons.movie),
                  ),
                ),
                const SizedBox(width: 16.0),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScrollingText(
                        text: title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4.0),
                      if (subtitleWidget != null)
                        subtitleWidget!
                      else if (subtitle != null)
                        ScrollingText(
                          text: subtitle!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8.0),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
