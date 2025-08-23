import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  String? errorMessage;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserEmail {
    return _auth.currentUser?.email;
  }

  Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      errorMessage = null;
      
     
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = e.message;
      return false;
    }
  }

  Future<bool> signup(String email, String password, String name) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      errorMessage = null;
  
      
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = e.message;
      return false;
    }
  }

  bool validateEmail(String email) {
    String pattern = r'^[^@]+@[^@]+\.[^@]+';
    return RegExp(pattern).hasMatch(email);
  }

  bool validatePassword(String password) {
    return password.length >= 6;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      errorMessage = null;
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = e.message;
      return false;
    }
  }

}
