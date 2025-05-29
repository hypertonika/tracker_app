import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final t = localeProvider.translations;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.translate('settings')),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.brightness_medium),
                    const SizedBox(width: 16),
                    Text(
                      t.translate('theme'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.brightness_auto,
                        color: themeProvider.useSystemTheme ? Theme.of(context).colorScheme.primary : null,
                      ),
                      tooltip: t.translate('systemDefault'),
                      onPressed: () => themeProvider.useSystemSettings(),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.light_mode,
                        color: themeProvider.themeMode == ThemeMode.light && !themeProvider.useSystemTheme ? Theme.of(context).colorScheme.primary : null,
                      ),
                      tooltip: t.translate('lightTheme'),
                      onPressed: () => themeProvider.setThemeMode(ThemeMode.light),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.dark_mode,
                        color: themeProvider.themeMode == ThemeMode.dark && !themeProvider.useSystemTheme ? Theme.of(context).colorScheme.primary : null,
                      ),
                      tooltip: t.translate('darkTheme'),
                      onPressed: () => themeProvider.setThemeMode(ThemeMode.dark),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(t.translate('language')),
            subtitle: Text(
              localeProvider.useSystemLocale
                  ? t.translate('systemDefault')
                  : localeProvider.getLanguageName(localeProvider.currentLanguage),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(t.translate('selectLanguage')),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.settings_brightness),
                        title: Text(Provider.of<LocaleProvider>(context).translations.translate('systemDefault')),
                        onTap: () {
                          localeProvider.useSystemSettings();
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Text('🇺🇸'),
                        title: Text(Provider.of<LocaleProvider>(context).translations.translate('english')),
                        onTap: () {
                          localeProvider.setLocale(const Locale('en'));
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Text('🇷🇺'),
                        title: Text(Provider.of<LocaleProvider>(context).translations.translate('russian')),
                        onTap: () {
                          localeProvider.setLocale(const Locale('ru'));
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Text('🇰🇿'),
                        title: Text(Provider.of<LocaleProvider>(context).translations.translate('kazakh')),
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