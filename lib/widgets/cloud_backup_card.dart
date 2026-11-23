import 'package:material_ui/material_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_database_service.dart';
import '../services/watchlist_repository.dart';
import 'custom_snackbar.dart';

class CloudBackupCard extends StatefulWidget {
  final WatchlistRepository repository;

  const CloudBackupCard({super.key, required this.repository});

  @override
  State<CloudBackupCard> createState() => _CloudBackupCardState();
}

class _CloudBackupCardState extends State<CloudBackupCard> {
  late final FirebaseAuthService _authService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authService = FirebaseAuthService(FirestoreDatabaseService());
  }

  Future<void> _handleLink(BuildContext ctx) async {
    setState(() => _isLoading = true);
    try {
      final credential = await _authService.signInWithGoogle();
      final uid = credential.user?.uid;
      if (uid == null) return;

      final result = await widget.repository.onAccountLinked(uid);

      if (result == LinkResult.conflictNeedsConfirmation) {
        if (!ctx.mounted) return;
        final confirmed = await showDialog<bool>(
          context: ctx,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Replace local data?'),
            content: const Text(
              'This account already has watchlists. '
              'Linking it will replace your current data with the data from this account.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Replace'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await widget.repository.confirmReplace(uid);
          await _syncToken(uid);
        } else {
          await _authService.signOut();
        }
      } else {
        await _syncToken(uid);
      }
    } catch (e) {
      if (!ctx.mounted) return;
      showCustomSnackBar(ctx, 'Link failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleUnlink(BuildContext ctx) async {
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await notificationService.updateStoredToken(null);
      }
      await _authService.signOut();
    } catch (e) {
      if (!ctx.mounted) return;
      showCustomSnackBar(ctx, 'Operation failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _syncToken(String uid) async {
    final token = await notificationService.getToken();
    await notificationService.updateStoredToken(token);
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
                const Icon(
                  Icons.cloud_sync_outlined,
                  size: 48,
                  color: Colors.blueAccent,
                ),
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
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton.icon(
                    icon: Icon(isLinked ? Icons.cloud_off : Icons.link),
                    label: Text(
                      isLinked
                          ? 'Disconnect Google Account'
                          : 'Link Google Account',
                    ),
                    onPressed: () {
                      if (isLinked) {
                        _handleUnlink(builderContext);
                      } else {
                        _handleLink(builderContext);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
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
