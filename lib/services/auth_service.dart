import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<User?> login(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _ensureUserDocument(result.user);
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _messageForAuthError(e);
    }
  }

  Future<User?> register(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _ensureUserDocument(result.user);
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw _messageForAuthError(e);
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> _ensureUserDocument(User? user) async {
    if (user == null) return;

    final userRef = _db.collection('users').doc(user.uid);
    await userRef.set({
      'uid': user.uid,
      'email': user.email ?? '',
      'name': user.displayName ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _db.collection('user_progress').doc(user.uid).set({
      'userId': user.uid,
      'totalSessions': 0,
      'totalMinutes': 0,
      'streakDays': 0,
      'aiSessions': 0,
      'totalAiAccuracy': 0,
      'averageAiAccuracy': 0,
      'lastSessionDate': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;

    if (user == null || email == null) {
      throw 'Please login again.';
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _messageForAuthError(e);
    }
  }

  String _messageForAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'operation-not-allowed':
        return 'Email/password login is not enabled in Firebase.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'network-request-failed':
        return 'Please check your internet connection.';
      case 'configuration-not-found':
        return 'Firebase Authentication is not configured for this app.';
      default:
        final message = error.message ?? 'Please try again.';
        return 'Authentication failed (${error.code}): $message';
    }
  }
}
