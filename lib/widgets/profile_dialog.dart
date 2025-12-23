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
                  border: Border.all(
                    color: theme.dividerColor,
                    width: 1,
                  ),
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
                                  backgroundColor:
                                      isAmoled ? AppTheme.amoledSurface : theme.cardColor,
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
                                    onTap: () => _showChangePhotoDialog(context, provider),
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
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                          ),
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

                        const SizedBox(height: 40),

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
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onError,
                                letterSpacing: 1.0,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.expense,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                      ],
                    ),

                    // Close Button
                    Positioned(
                      top: -16,
                      right: -16,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: theme.iconTheme.color?.withOpacity(0.6)),
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
          decoration: const InputDecoration(
            hintText: 'Enter image URL',
          ),
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
}
