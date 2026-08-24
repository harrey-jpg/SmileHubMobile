import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  User _requireUser() {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw StateError('No user is currently signed in.');
    }

    return user;
  }

  Future<Map<String, String>> loadProfile() async {
    final User user = _requireUser();

    final DocumentSnapshot<Map<String, dynamic>> document =
        await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

    final Map<String, dynamic> data =
        document.data() ?? <String, dynamic>{};

    String readString(String field) {
      final dynamic value = data[field];
      return value is String ? value : '';
    }

    final String firestoreName = readString('fullName');

    return <String, String>{
      'fullName': firestoreName.isNotEmpty
          ? firestoreName
          : user.displayName ?? '',
      'email': user.email ?? readString('email'),
      'mobile': readString('mobile'),
      'clinic': readString('clinic'),
      'buyerType': readString('buyerType').isNotEmpty
          ? readString('buyerType')
          : 'Dental Professional',
    };
  }

  Future<void> saveProfile({
    required String fullName,
    required String mobile,
    required String clinic,
    required String buyerType,
  }) async {
    final User user = _requireUser();

    await _firestore.collection('users').doc(user.uid).set(
      <String, dynamic>{
        'uid': user.uid,
        'fullName': fullName.trim(),
        'email': user.email ?? '',
        'mobile': mobile.trim(),
        'clinic': clinic.trim(),
        'buyerType': buyerType,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await user.updateDisplayName(fullName.trim());
  }
}