import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                ListTile(
                  leading: const Icon(Icons.email),
                  title: Text(user.email ?? ''),
                  subtitle: const Text('Email'),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.brightness_medium),
                  title: const Text('Theme'),
                  subtitle: Text(
                    themeProvider.useSystemTheme
                        ? 'System default'
                        : (isDarkMode ? 'Dark theme' : 'Light theme'),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
                        onPressed: () {
                          themeProvider.toggleTheme();
                        },
                        tooltip: isDarkMode ? 'Light theme' : 'Dark theme',
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.settings_brightness),
                        onPressed: () {
                          themeProvider.useSystemSettings();
                        },
                        tooltip: 'System default',
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Language'),
                  subtitle: Text(
                    localeProvider.useSystemLocale
                        ? 'System default'
                        : localeProvider.getLanguageName(localeProvider.currentLanguage),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Select language'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.settings_brightness),
                              title: const Text('System default'),
                              onTap: () {
                                localeProvider.useSystemSettings();
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              leading: const Text('🇺🇸'),
                              title: const Text('English'),
                              onTap: () {
                                localeProvider.setLocale(const Locale('en'));
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              leading: const Text('🇷🇺'),
                              title: const Text('Русский'),
                              onTap: () {
                                localeProvider.setLocale(const Locale('ru'));
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              leading: const Text('🇰🇿'),
                              title: const Text('Қазақша'),
                              onTap: () {
                                localeProvider.setLocale(const Locale('kk'));
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  onPressed: () async {
                    await context.read<AuthService>().signOut();
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  },
                ),
              ],
            ),
    );
  }
} 