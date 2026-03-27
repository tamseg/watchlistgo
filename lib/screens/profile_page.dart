import 'package:flutter/material.dart';
import '../widgets/cloud_backup_card.dart';
import '../services/watchlist_repository.dart';

class ProfilePage extends StatelessWidget {
  final WatchlistRepository repository;

  const ProfilePage({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 48),
            CloudBackupCard(repository: repository),
          ],
        ),
      ),
    );
  }
}
