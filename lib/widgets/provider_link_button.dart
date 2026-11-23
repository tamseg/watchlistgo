import 'package:material_ui/material_ui.dart';
import '../theme/app_theme.dart';

class ProviderLinkButton extends StatelessWidget {
  final String providerId;
  final bool isLinked;
  final bool isLoading;
  final VoidCallback onPressed;

  const ProviderLinkButton({
    super.key,
    required this.providerId,
    required this.isLinked,
    required this.isLoading,
    required this.onPressed,
  });

  String _getProviderName(String id) {
    switch (id) {
      case 'google.com':
        return 'Google';
      case 'facebook.com':
        return 'Meta';
      case 'apple.com':
        return 'Apple';
      default:
        return 'Account';
    }
  }

  Widget _getProviderLogo(String id) {
    String? logoUrl;
    switch (id) {
      case 'google.com':
        logoUrl =
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1024px-Google_%22G%22_logo.svg.png';
        break;
      case 'facebook.com':
        logoUrl =
            'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b8/2021_Facebook_icon.svg/1024px-2021_Facebook_icon.svg.png';
        break;
      case 'apple.com':
        logoUrl =
            'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Apple_logo_black.svg/1024px-Apple_logo_black.svg.png';
        break;
    }

    if (logoUrl != null) {
      return Image.network(
        logoUrl,
        height: 20,
        width: 20,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.link, size: 20),
      );
    }
    return const Icon(Icons.link, size: 20);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final providerName = _getProviderName(providerId);

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: _getProviderLogo(providerId),
        label: Text(
          isLinked ? 'Unlink from $providerName' : 'Link $providerName account',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkTextColor,
          ),
        ),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: AppTheme.placeholderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
