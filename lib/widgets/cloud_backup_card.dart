import 'package:material_ui/material_ui.dart';
import '../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_database_service.dart';
import '../services/watchlist_repository.dart';
import 'custom_snackbar.dart';
import 'provider_link_button.dart';

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
          await notificationService.syncRegistration();
        } else {
          await _authService.signOut();
        }
      } else {
        await notificationService.syncRegistration();
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
        await notificationService.updateStoredFid(null);
      }
      await _authService.signOut();
    } catch (e) {
      if (!ctx.mounted) return;
      showCustomSnackBar(ctx, 'Operation failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (builderContext, snapshot) {
        final user = snapshot.data;
        final isLinked = snapshot.hasData && user != null;

        String? activeProviderId;
        if (isLinked && user.providerData.isNotEmpty) {
          activeProviderId = user.providerData.first.providerId;
        }

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.scaffoldColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                spreadRadius: 4,
                offset: Offset.zero,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isLinked) ...[
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: user.photoURL != null
                            ? NetworkImage(user.photoURL!)
                            : null,
                        child: user.photoURL == null
                            ? const Icon(
                                Icons.person,
                                size: 30,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cloud Backup',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkTextColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isLinked
                                ? 'Linked via ${_getProviderDisplayName(activeProviderId)}'
                                : 'Connect an account to safely back up and sync your watchlists.',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ProviderLinkButton(
                  providerId: activeProviderId ?? 'google.com',
                  isLinked: isLinked,
                  isLoading: _isLoading,
                  onPressed: () {
                    if (isLinked) {
                      _handleUnlink(builderContext);
                    } else {
                      _handleLink(builderContext);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getProviderDisplayName(String? providerId) {
    switch (providerId) {
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
}
