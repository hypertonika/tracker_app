import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../main.dart';
import '../services/user_prefs_service.dart';
import '../providers/transaction_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => v == null || v.isEmpty ? 'Enter email' : null,
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) => v == null || v.length < 6 ? 'Min 6 chars' : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),
                _loading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _loading ? null : _login,
                        child: const Text('Login'),
                      ),
                TextButton(
                  onPressed: _loading ? null : () => Navigator.pushNamed(context, '/register'),
                  child: const Text('No account? Register'),
                ),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () async {
                          // Очищаем данные перед входом в гостевой режим
                          final userPrefsService = UserPrefsService();
                          await userPrefsService.clearGuestData();
                          
                          if (!mounted) return;
                          context.read<TransactionProvider>().clearAndLoad([]);
                          context.read<ThemeProvider>().useSystemSettings();
                          context.read<LocaleProvider>().useSystemSettings();
                          context.read<GuestModeProvider>().setGuest(true);
                          
                          if (!mounted) return;
                          Navigator.pushReplacementNamed(context, '/');
                        },
                  child: const Text('Continue as Guest'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final user = await auth.signIn(_emailController.text, _passwordController.text);
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final data = doc.data() ?? {};
        final userPrefsService = UserPrefsService();
        final transactions = await userPrefsService.loadTransactionsFromFirestore(user.uid);
        final theme = data['theme'] ?? 'system';
        final language = data['language'] ?? 'system';
        await userPrefsService.clearGuestData();
        if (!mounted) return;
        context.read<TransactionProvider>().clearAndLoad(transactions);
        context.read<ThemeProvider>().setThemeFromString(theme);
        context.read<LocaleProvider>().setLocaleFromString(language);
        context.read<GuestModeProvider>().setGuest(false);
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      setState(() => _error = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }
} 