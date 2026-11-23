import 'package:material_ui/material_ui.dart';
import '../theme/app_theme.dart';
import '../widgets/cloud_backup_card.dart';
import '../services/watchlist_repository.dart';
import 'actions_page.dart';
import 'stats_page.dart';
import '../theme/theme_controller.dart';

class ProfilePage extends StatefulWidget {
  final WatchlistRepository repository;
  final ThemeController themeController;

  const ProfilePage({
    super.key,
    required this.repository,
    required this.themeController,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('App Theme'),
          content: RadioGroup<String>(
            groupValue: widget.themeController.currentTheme,
            onChanged: (String? value) {
              if (value != null) {
                widget.themeController.updateTheme(value);
                Navigator.pop(context);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: ['Light', 'Dark', 'System Default'].map((theme) {
                return RadioListTile<String>(
                  title: Text(theme),
                  value: theme,
                  controlAffinity: ListTileControlAffinity.leading,
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24.0,
          right: 24.0,
          top: 48.0,
          bottom: MediaQuery.paddingOf(context).bottom + 16.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CloudBackupCard(repository: widget.repository),
            const SizedBox(height: 32),
            const Text(
              'Insights',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w400,
                color: AppTheme.secondaryTextColor,
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Watchlist Stats',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
              ),
              trailing: const Icon(Icons.chevron_right, size: 32),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StatsPage()),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Preferences',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w400,
                color: AppTheme.secondaryTextColor,
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'App Theme',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                widget.themeController.currentTheme,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.secondaryTextColor,
                ),
              ),
              onTap: _showThemeDialog,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Region & Language',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
              ),
              trailing: const Icon(Icons.chevron_right, size: 32),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActionsPage(repository: widget.repository),
                  ),
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Notifications',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w400,
                color: AppTheme.secondaryTextColor,
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Lists & Account',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
              ),
              trailing: const Icon(Icons.chevron_right, size: 32),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActionsPage(repository: widget.repository),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
