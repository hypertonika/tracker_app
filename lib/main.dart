import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/about_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/connectivity_service.dart';
import 'l10n/translations.dart';
import 'providers/navigation_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class GuestModeProvider with ChangeNotifier {
  bool _isGuest = false;
  bool get isGuest => _isGuest;
  void setGuest(bool value) {
    _isGuest = value;
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => GuestModeProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => ConnectivityService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => GuestModeProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => ConnectivityService()),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, _) {
          return MaterialApp(
            title: 'Tracker',
            theme: themeProvider.themeData,
            locale: localeProvider.locale,
            localizationsDelegates: [
              TranslationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: localeProvider.supportedLocales,
            initialRoute: '/',
            routes: {
              '/': (context) => const AuthGate(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/about': (context) => const AboutScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final guestModeProvider = context.read<GuestModeProvider>();

    return StreamBuilder<User?>(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          if (guestModeProvider.isGuest) {
            Future.microtask(() => guestModeProvider.setGuest(false));
          }
          return const RootNavigation();
        } else {
          if (!guestModeProvider.isGuest) {
            Future.microtask(() => guestModeProvider.setGuest(true));
          }
          return const RootNavigation();
        }
      },
    );
  }
}

class RootNavigation extends StatefulWidget {
  const RootNavigation({super.key});

  @override
  State<RootNavigation> createState() => _RootNavigationState();
}

class _RootNavigationState extends State<RootNavigation> {
  @override
  void didUpdateWidget(covariant RootNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    final navigationProvider = context.read<NavigationProvider>();
    final isGuest = context.read<GuestModeProvider>().isGuest;
    final user = FirebaseAuth.instance.currentUser;

    final int newItemsLength = (
        1 + // Home
        1 + // About
        (user != null && !isGuest ? 1 : 0) + // Profile
        (!isGuest ? 1 : 0) // Settings
    );

    if (navigationProvider.selectedIndex >= newItemsLength) {
      Future.microtask(() => navigationProvider.setSelectedIndex(0));
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigationProvider = context.watch<NavigationProvider>();
    final isGuest = context.watch<GuestModeProvider>().isGuest;
    final user = FirebaseAuth.instance.currentUser;
    final translations = context.watch<LocaleProvider>().translations;

    final List<Widget> pages = [
      HomeScreen(isGuest: isGuest),
      const AboutScreen(),
      if (user != null && !isGuest) const ProfileScreen(),
      if (!isGuest) const SettingsScreen(),
    ];

    final items = [
      BottomNavigationBarItem(icon: const Icon(Icons.home), label: translations.translate('home')),
      BottomNavigationBarItem(icon: const Icon(Icons.info_outline), label: translations.translate('about')),
      if (user != null && !isGuest)
        BottomNavigationBarItem(icon: const Icon(Icons.person), label: translations.translate('profile')),
      if (!isGuest)
        BottomNavigationBarItem(icon: const Icon(Icons.settings), label: translations.translate('settings')),
    ];

    int currentIndex = navigationProvider.selectedIndex;
    if (currentIndex >= pages.length) {
        currentIndex = 0;
    }

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: items,
        currentIndex: currentIndex,
        onTap: (i) {
          if (isGuest) {
            final selectedItemLabel = items[i].label;
            if (selectedItemLabel == translations.translate('profile') || selectedItemLabel == translations.translate('settings')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please log in to access this feature')),
                );
            } else {
                 navigationProvider.setSelectedIndex(i);
            }
          } else {
             navigationProvider.setSelectedIndex(i);
          }
        },
      ),
    );
  }
}

