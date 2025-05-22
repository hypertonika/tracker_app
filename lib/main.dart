import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => ConnectivityService()),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, _) {
          return MaterialApp(
            title: 'Tracker',
            theme: themeProvider.themeData,
            locale: localeProvider.locale,
            localizationsDelegates: localeProvider.localizationsDelegates,
            supportedLocales: localeProvider.supportedLocales,
            initialRoute: '/',
            routes: {
              '/': (context) => const RootNavigation(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/about': (context) => const AboutScreen(),
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
    final guestMode = context.watch<GuestModeProvider>().isGuest;
    return StreamBuilder<User?>(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          // Пользователь авторизован
          return const RootNavigation();
        } else if (guestMode) {
          // Гостевой режим
          return const RootNavigation();
        } else {
          // Гость
          return const LoginScreen();
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
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final l10n = AppLocalizations.of(context)!;
    final isGuest = context.watch<GuestModeProvider>().isGuest;
    final pages = [
      const HomeScreen(),
      const AboutScreen(),
      if (user != null && !isGuest) const ProfileScreen(),
      if (!isGuest) const SettingsScreen(),
    ];
    final items = [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: l10n.home),
      BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: l10n.about),
      if (user != null && !isGuest)
        BottomNavigationBarItem(icon: Icon(Icons.person), label: l10n.profile),
      if (!isGuest)
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: l10n.settings),
    ];
    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) {
          // Если гость пытается перейти на приватные вкладки
          if (isGuest && (i == 2 || i == 3)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Please log in to access this feature')),
            );
            return;
          }
          setState(() => _selectedIndex = i);
        },
        items: items,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
