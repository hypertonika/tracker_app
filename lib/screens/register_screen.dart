import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/user_prefs_service.dart';
import '../providers/transaction_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction.dart' as mymodel;
import '../main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
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
                        onPressed: _loading ? null : _register,
                        child: const Text('Register'),
                      ),
                TextButton(
                  onPressed: _loading ? null : () => Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final user = await auth.register(_emailController.text, _passwordController.text);
      if (user != null) {
        // Миграция гостевых данных
        final userPrefsService = UserPrefsService();
        final guestData = await userPrefsService.loadGuestData();
        List<mymodel.Transaction> guestTx = [];
        if (guestData['transactions'] is List<mymodel.Transaction>) {
          guestTx = guestData['transactions'] as List<mymodel.Transaction>;
        } else if (guestData['transactions'] is List) {
          guestTx = (guestData['transactions'] as List)
              .map((e) => e is mymodel.Transaction ? e : mymodel.Transaction.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
        // Сохраняем тему и язык
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'theme': guestData['theme'] ?? 'system',
          'language': guestData['language'] ?? 'system',
        }, SetOptions(merge: true));
        // Сохраняем транзакции как подколлекцию
        await userPrefsService.saveTransactionsToFirestore(user.uid, guestTx);
        await userPrefsService.clearGuestData();
        if (!mounted) return;
        context.read<TransactionProvider>().clearAndLoad(guestTx);
        context.read<ThemeProvider>().setThemeFromString(guestData['theme'] ?? 'system');
        context.read<LocaleProvider>().setLocaleFromString(guestData['language'] ?? 'system');
        context.read<GuestModeProvider>().setGuest(false);
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      setState(() => _error = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }
} 