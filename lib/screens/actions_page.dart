import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:watchlistgo/services/firestore_database_service.dart';
import 'package:watchlistgo/widgets/custom_snackbar.dart';
import '../services/watchlist_repository.dart';
import '../services/firebase_auth_service.dart';

class ActionsPage extends StatefulWidget {
  final WatchlistRepository repository;

  const ActionsPage({super.key, required this.repository});

  @override
  State<ActionsPage> createState() => _ActionsPageState();
}

class _ActionsPageState extends State<ActionsPage> {
  bool _isClearing = false;
  bool _isForgetting = false;

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Clear all watchlists?'),
          content: const Text(
              'Are you sure you want to remove all saved movies and TV shows? Your profile and settings will remain, but your lists will be completely emptied. This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                setState(() => _isClearing = true);
                try {
                  await widget.repository.clearAll();
                  if (context.mounted) {
                    showCustomSnackBar(context, 'Watchlists cleared successfully.');
                  }
                } catch (e) {
                  if (context.mounted) {
                    showCustomSnackBar(context, 'Error clearing lists: $e');
                  }
                } finally {
                  if (mounted) setState(() => _isClearing = false);
                }
              },
              child: const Text(
                'Clear Lists',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showForgetMeConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Permanently forget your profile?'),
          content: const Text(
              'This will permanently erase your profile, wipe your cloud backups, and delete all your watchlists and notification settings. We will have no record of you. This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                setState(() => _isForgetting = true);
                try {
                  await widget.repository.clearAll();
                  await widget.repository.forgetLocalLink();
                  await FirebaseAuthService(FirestoreDatabaseService()).deleteAccount();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                } on FirebaseAuthException catch (e) {
                  if (context.mounted) {
                    final message = e.code == 'requires-recent-login' ? e.message! : 'Error forgetting profile: $e';
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Action Required'),
                        content: Text(message),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    showCustomSnackBar(context, 'An unexpected error occurred: $e');
                  }
                } finally {
                  if (mounted) setState(() => _isForgetting = false);
                }
              },
              child: const Text('Forget Me'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Actions')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _isClearing || _isForgetting ? null : () => _showClearConfirmation(context),
              child: _isClearing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                    )
                  : const Text('Clear Watchlists'),
            ),
            const SizedBox(height: 16),
            if (FirebaseAuth.instance.currentUser != null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isClearing || _isForgetting ? null : () => _showForgetMeConfirmation(context),
                child: _isForgetting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Forget Me'),
              ),
          ],
        ),
      ),
    );
  }
}
