import 'package:material_ui/material_ui.dart';
import '../theme/app_theme.dart';
import '../widgets/cloud_backup_card.dart';
import '../services/watchlist_repository.dart';
import 'actions_page.dart';

class ProfilePage extends StatelessWidget {
  final WatchlistRepository repository;

  const ProfilePage({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: AppTheme.buildFrostedGlassBackground(),
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          left: 24.0,
          right: 24.0,
          top: 48.0,
          bottom: 24.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CloudBackupCard(repository: repository),
            const SizedBox(height: 24),
            ListTile(
              title: const Text(
                'Actions',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
              ),
              trailing: const Icon(Icons.chevron_right, size: 32),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActionsPage(repository: repository),
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
