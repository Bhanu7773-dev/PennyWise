import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/money_provider.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';

class ProfileDialog extends StatelessWidget {
  const ProfileDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MoneyProvider>(context);

    final theme = Theme.of(context);
    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Blur Effect
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.black.withOpacity(0.2)),
            ),
          ),
          Center(
            child: Material(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(32),
              elevation: 20,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: theme.dividerColor, width: 1),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Avatar with edit button
                        Hero(
                          tag: 'profile_ring',
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.primary,
                                    width: 3,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: isAmoled
                                      ? AppTheme.amoledSurface
                                      : theme.cardColor,
                                  backgroundImage: provider.photoURL != null
                                      ? NetworkImage(provider.photoURL!)
                                      : null,
                                  child: provider.photoURL == null
                                      ? Icon(
                                          Icons.person,
                                          size: 50,
                                          color: theme.iconTheme.color,
                                        )
                                      : null,
                                ),
                              ),
                              // Pencil button
                              Positioned(
                                right: -4,
                                bottom: -4,
                                child: Material(
                                  color: theme.cardColor,
                                  shape: const CircleBorder(),
                                  elevation: 4,
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () => _showChangePhotoDialog(
                                      context,
                                      provider,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.edit,
                                        size: 18,
                                        color: theme.iconTheme.color,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // User Name
                        Text(
                          provider.userName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleLarge?.color,
                            letterSpacing: 0.5,
                          ),
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                        const SizedBox(height: 8),

                        // Email/Account Type
                        Text(
                          provider.userId != null &&
                                  !provider.settingsBox.get(
                                    'isGuest',
                                    defaultValue: true,
                                  )
                              ? 'Google Account'
                              : 'Guest Account',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.6),
                          ),
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

                        const SizedBox(height: 32),

                        // Logout Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // Close dialog first
                              Navigator.pop(context);

                              // Sign out logic
                              await AuthService().signOut();
                              if (context.mounted) {
                                await provider.logout();
                                if (context.mounted) {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/onboarding',
                                    (route) => false,
                                  );
                                }
                              }
                            },
                            icon: Icon(
                              Icons.logout_rounded,
                              color: theme.colorScheme.onError,
                            ),
                            label: Text(
                              'LOGOUT',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onError,
                                letterSpacing: 1.0,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.expense,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

                        const SizedBox(height: 12),

                        // Delete Main Account Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showDeleteAccountConfirmationDialog(
                                  context,
                                  provider,
                                ),
                            icon: const Icon(
                              Icons.delete_forever_rounded,
                              color: Colors.red,
                              size: 20,
                            ),
                            label: const Text(
                              'DELETE ACCOUNT & DATA',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                                letterSpacing: 0.5,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.red.withOpacity(0.5),
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
                      ],
                    ),

                    // Close Button
                    Positioned(
                      top: -16,
                      right: -16,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: theme.iconTheme.color?.withOpacity(0.6),
                        ),
                        splashRadius: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePhotoDialog(BuildContext context, MoneyProvider provider) {
    final controller = TextEditingController(text: provider.photoURL ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change profile picture'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter image URL'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              final url = controller.text.trim();
              await provider.setPhotoURL(url.isEmpty ? null : url);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('SAVE'),
          ),
          if (provider.photoURL != null) ...[
            TextButton(
              onPressed: () async {
                await provider.setPhotoURL(null);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('REMOVE'),
            ),
          ],
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmationDialog(
    BuildContext context,
    MoneyProvider provider,
  ) {
    final isAmoled = provider.appThemeMode == AppThemeMode.amoled;
    final isLight = provider.appThemeMode == AppThemeMode.light;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isAmoled
            ? Colors.black
            : (isLight ? Colors.white : const Color(0xFF1E293B)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isLight
              ? const BorderSide(color: Colors.black12)
              : (isAmoled
                    ? const BorderSide(color: Colors.white24)
                    : BorderSide.none),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Account?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isLight ? Colors.black : Colors.white,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently delete your user profile, accounts, transactions, budgets, goals, and all cloud database records.',
              style: TextStyle(
                color: isLight
                    ? Colors.black87
                    : (isAmoled ? Colors.white70 : Colors.white70),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone.',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'CANCEL',
              style: TextStyle(
                color: isLight ? Colors.black54 : Colors.white60,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(dialogContext); // close alert dialog
              Navigator.pop(context); // close profile dialog

              // Show loading overlay
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingCtx) => Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isAmoled
                          ? Colors.black
                          : (isLight ? Colors.white : const Color(0xFF1E293B)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isLight ? Colors.black12 : Colors.white12,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Deleting all account data...',
                          style: TextStyle(
                            color: isLight ? Colors.black : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              try {
                await provider.permanentlyDeleteUserAccount();
              } catch (e) {
                debugPrint('Error during account deletion: $e');
              }

              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/onboarding',
                  (route) => false,
                );
              }
            },
            icon: const Icon(
              Icons.delete_forever,
              size: 18,
              color: Colors.white,
            ),
            label: const Text(
              'DELETE PERMANENTLY',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
