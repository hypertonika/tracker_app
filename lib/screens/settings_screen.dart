import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.brightness_medium),
            title: Text(l10n.theme),
            subtitle: Text(
              themeProvider.useSystemTheme
                  ? l10n.systemDefault
                  : (isDarkMode ? l10n.darkTheme : l10n.lightTheme),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
                  onPressed: () {
                    themeProvider.toggleTheme();
                  },
                  tooltip: isDarkMode ? l10n.lightTheme : l10n.darkTheme,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.settings_brightness),
                  onPressed: () {
                    themeProvider.useSystemSettings();
                  },
                  tooltip: l10n.systemDefault,
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(
              localeProvider.useSystemLocale
                  ? l10n.systemDefault
                  : localeProvider.getLanguageName(localeProvider.currentLanguage),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.selectLanguage),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.settings_brightness),
                        title: Text(l10n.systemDefault),
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
        ],
      ),
    );
  }
} 