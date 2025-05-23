import 'package:firebase_auth/firebase_auth.dart';
import 'user_prefs_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<User?> signIn(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return result.user;
  }

  Future<User?> register(String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    return result.user;
  }

  Future<void> signOut() async {
    // Очищаем данные пользователя перед выходом
    final userPrefsService = UserPrefsService();
    await userPrefsService.clearGuestData();
    await _auth.signOut();
  }
} 