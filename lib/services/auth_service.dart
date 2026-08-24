import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUp({
    required String fullName,
    required String email,
    required String mobile,
    required String password,
  }) async {
    final UserCredential credential =
        await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final User? user = credential.user;

    if (user == null) {
      throw StateError('Unable to create user.');
    }

    await user.updateDisplayName(fullName.trim());

    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'fullName': fullName.trim(),
      'email': email.trim(),
      'mobile': mobile.trim(),
      'role': 'customer',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Mirror into the accounts collection so the record shows up in the
    // web admin's Account Management (same as web registrations).
    try {
      await _firestore.collection('accounts').doc(email.trim()).set(
        <String, dynamic>{
          'name': fullName.trim(),
          'email': email.trim(),
          'role': 'customer',
          'status': 'active',
        },
      );
    } catch (_) {
      // Non-fatal: admins still see this account via the users collection.
    }

    return credential;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() {
    return _auth.signOut();
  }
}