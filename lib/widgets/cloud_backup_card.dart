import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_database_service.dart';
import 'custom_snackbar.dart';

class CloudBackupCard extends StatefulWidget {
  const CloudBackupCard({super.key});

  @override
  State<CloudBackupCard> createState() => _CloudBackupCardState();
}

class _CloudBackupCardState extends State<CloudBackupCard> {
  late final FirebaseAuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = FirebaseAuthService(FirestoreDatabaseService());
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade800),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: StreamBuilder<User?>(
          stream: _authService.authStateChanges,
          builder: (builderContext, snapshot) {
            final isLinked = snapshot.hasData && snapshot.data != null;

            return Column(
              children: [
                const Icon(Icons.cloud_sync_outlined, size: 48, color: Colors.blueAccent),
                const SizedBox(height: 16),
                const Text(
                  'Sync Across Devices',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  isLinked
                      ? 'Your watchlists are safely backed up to the cloud and synced across devices.'
                      : 'Link your Google account to back up and sync your watchlists across devices automatically.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: Icon(isLinked ? Icons.cloud_off : Icons.link),
                  label: Text(isLinked ? 'Disconnect Google Account' : 'Link Google Account'),
                  onPressed: () async {
                    try {
                      if (isLinked) {
                        await _authService.signOut();
                      } else {
                        await _authService.signInWithGoogle();
                      }
                    } catch (e) {
                      if (!builderContext.mounted) return;
                      showCustomSnackBar(builderContext, 'Operation failed. Please try again.');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
