import 'package:digital_bookshelf/services/google_drive_services.dart';
import 'package:digital_bookshelf/services/auth_services.dart';
import 'package:digital_bookshelf/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthServices _authService = AuthServices();

  bool _isLoading = false;
  String? _errorMessage;

  // Login with Google 
  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'An error occurred during Google Sign-In.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Check if the signed-in user used Google (has Drive access)
  bool _isGoogleUser(User user) =>
      user.providerData.any((p) => p.providerId == 'google.com');

  // Sync to Drive
  Future<void> _syncData() async {
    try {
      final driveService = context.read<GoogleDriveServices>();
      await driveService.syncToCloud();
      if (mounted) {
        _showSnack('Sync complete! Your data is saved to Google Drive', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _showSnack(e.toString().replaceFirst('Exception: ', ''), AppTheme.error, seconds: 8);
      }
    }
  }

  // Restore from Drive
  Future<void> _restoreData() async {
    final confirmed = await _confirmRestore();
    if (!confirmed || !mounted) return;

    try {
      final driveService = context.read<GoogleDriveServices>();
      await driveService.restoreFromCloud();
      if (mounted) {
        _showSnack('Restore complete! Your bookshelf has been rebuilt', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Restore error: $e', AppTheme.error, seconds: 8);
      }
    }
  }

  Future<bool> _confirmRestore() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from Drive?'),
        content: const Text(
          'This will merge your Google Drive backup into your local bookshelf. '
          'Existing categories and documents will not be duplicated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSnack(String msg, Color bg, {int seconds = 4}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: bg,
      duration: Duration(seconds: seconds),
      behavior: SnackBarBehavior.floating,
    ));
  }

  // Build
  @override
  Widget build(BuildContext context) {
    final driveService = context.watch<GoogleDriveServices>();
    final isBusy = driveService.isSyncing || driveService.isRestoring;
    final syncStatus = driveService.syncProgress.isNotEmpty ? driveService.syncProgress : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: StreamBuilder<User?>(
        stream: _authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;

          // Not logged in
          if (user == null) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.cloud_sync,
                      size: 100,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Sign in with your Google account to back up and restore your bookshelf.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    
                    // Error message
                    const SizedBox(height: 48),
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.error),
                        ),
                      ),
                      
                    // Sign in with google button
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _loginWithGoogle,
                      icon: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.g_mobiledata, size: 32),
                      label: const Text(
                        'Sign in with Google',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final isGoogle = _isGoogleUser(user);
          final photoUrl = user.photoURL;

          // Logged in
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Avatar
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primary,
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? const Icon(Icons.person,
                          size: 50, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user.displayName ?? user.email ?? 'User',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (user.email != null && user.displayName != null)
                Text(
                  user.email!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              const SizedBox(height: 8),

              // Google badge
              if (isGoogle)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text('Signed in with Google',
                        style: TextStyle(
                            color: Colors.blue.shade700, fontSize: 13)),
                  ],
                ),

              const SizedBox(height: 40),

              // Google Drive Sync section
              const Text('Google Drive',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
              const SizedBox(height: 8),

                Card(
                  child: Column(
                    children: [
                      // Status bar
                      if (isBusy)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  syncStatus ?? 'Working…',
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Sync to Drive
                      ListTile(
                        leading: const Icon(Icons.cloud_upload_outlined,
                            color: AppTheme.primary),
                        title: const Text('Sync to Drive'),
                        subtitle: const Text(
                            'Back up categories & files to Google Drive'),
                        trailing: isBusy
                            ? null
                            : const Icon(Icons.chevron_right),
                        onTap: isBusy ? null : _syncData,
                      ),

                      const Divider(height: 1, indent: 16, endIndent: 16),

                      // Restore from Drive
                      ListTile(
                        leading: const Icon(Icons.cloud_download_outlined,
                            color: AppTheme.primary),
                        title: const Text('Restore from Drive'),
                        subtitle: const Text(
                            'Merge your Drive backup into this device'),
                        trailing: isBusy
                            ? null
                            : const Icon(Icons.chevron_right),
                        onTap: isBusy ? null : _restoreData,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Account section
              const Text('Account',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.logout, color: AppTheme.error),
                  title: const Text('Sign Out',
                      style: TextStyle(color: AppTheme.error)),
                  onTap: isBusy
                      ? null
                      : () async => await _authService.signOut(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
