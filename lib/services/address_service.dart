import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddressService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  User _requireUser() {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw StateError('You must log in first.');
    }

    return user;
  }

  CollectionReference<Map<String, dynamic>> _addresses(
    User user,
  ) {
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('addresses');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>
      watchAddresses() {
    final User user = _requireUser();

    return _addresses(user).snapshots();
  }

  Future<void> addAddress({
    required String label,
    required String recipient,
    required String phone,
    required String city,
    required String barangay,
    required String street,
    required String postalCode,
    required bool isDefault,
  }) async {
    final User user = _requireUser();

    final CollectionReference<Map<String, dynamic>>
        collection = _addresses(user);

    final QuerySnapshot<Map<String, dynamic>> existing =
        await collection.get();

    final bool makeDefault =
        isDefault || existing.docs.isEmpty;

    final WriteBatch batch = _firestore.batch();

    if (makeDefault) {
      for (final document in existing.docs) {
        batch.set(
          document.reference,
          <String, dynamic>{
            'isDefault': false,
          },
          SetOptions(merge: true),
        );
      }
    }

    final DocumentReference<Map<String, dynamic>>
        addressReference = collection.doc();

    batch.set(
      addressReference,
      <String, dynamic>{
        'addressId': addressReference.id,
        'label': label,
        'recipient': recipient.trim(),
        'phone': phone.trim(),
        'city': city.trim(),
        'barangay': barangay.trim(),
        'street': street.trim(),
        'postalCode': postalCode.trim(),
        'fullAddress':
            '${street.trim()}, ${barangay.trim()}, '
            '${city.trim()} ${postalCode.trim()}',
        'isDefault': makeDefault,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }
  Future<void> updateAddress({
  required String addressId,
  required String label,
  required String recipient,
  required String phone,
  required String city,
  required String barangay,
  required String street,
  required String postalCode,
  required bool isDefault,
}) async {
  final User user = _requireUser();

  final CollectionReference<Map<String, dynamic>>
      collection = _addresses(user);

  final DocumentReference<Map<String, dynamic>>
      addressReference = collection.doc(addressId);

  final DocumentSnapshot<Map<String, dynamic>>
      currentAddress = await addressReference.get();

  if (!currentAddress.exists) {
    throw StateError('Address not found.');
  }

  final QuerySnapshot<Map<String, dynamic>> allAddresses =
      await collection.get();

  final bool wasDefault =
      currentAddress.data()?['isDefault'] == true;

  final bool anotherDefaultExists =
      allAddresses.docs.any(
    (document) =>
        document.id != addressId &&
        document.data()['isDefault'] == true,
  );

  final bool makeDefault =
      isDefault ||
      allAddresses.docs.length == 1 ||
      (wasDefault && !anotherDefaultExists);

  final WriteBatch batch = _firestore.batch();

  if (makeDefault) {
    for (final document in allAddresses.docs) {
      if (document.id == addressId) continue;

      batch.set(
        document.reference,
        <String, dynamic>{
          'isDefault': false,
        },
        SetOptions(merge: true),
      );
    }
  }

  batch.set(
    addressReference,
    <String, dynamic>{
      'label': label,
      'recipient': recipient.trim(),
      'phone': phone.trim(),
      'city': city.trim(),
      'barangay': barangay.trim(),
      'street': street.trim(),
      'postalCode': postalCode.trim(),
      'fullAddress':
          '${street.trim()}, ${barangay.trim()}, '
          '${city.trim()} ${postalCode.trim()}',
      'isDefault': makeDefault,
      'updatedAt': FieldValue.serverTimestamp(),
    },
    SetOptions(merge: true),
  );

  await batch.commit();
}

Future<void> deleteAddress(String addressId) async {
  final User user = _requireUser();

  final CollectionReference<Map<String, dynamic>>
      collection = _addresses(user);

  final DocumentReference<Map<String, dynamic>>
      addressReference = collection.doc(addressId);

  final DocumentSnapshot<Map<String, dynamic>>
      addressSnapshot = await addressReference.get();

  if (!addressSnapshot.exists) {
    return;
  }

  final bool wasDefault =
      addressSnapshot.data()?['isDefault'] == true;

  await addressReference.delete();

  // Kapag default address ang dinelete,
  // gawing default ang isa sa natitirang addresses.
  if (wasDefault) {
    final QuerySnapshot<Map<String, dynamic>> remaining =
        await collection.limit(1).get();

    if (remaining.docs.isNotEmpty) {
      await remaining.docs.first.reference.set(
        <String, dynamic>{
          'isDefault': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
  }
}
Future<Map<String, dynamic>?> getDefaultAddress() async {
  final User user = _requireUser();

  final QuerySnapshot<Map<String, dynamic>> snapshot =
      await _addresses(user).get();

  if (snapshot.docs.isEmpty) {
    return null;
  }

  final QueryDocumentSnapshot<Map<String, dynamic>>
      selectedDocument = snapshot.docs.firstWhere(
    (document) => document.data()['isDefault'] == true,
    orElse: () => snapshot.docs.first,
  );

  return <String, dynamic>{
    'addressId': selectedDocument.id,
    ...selectedDocument.data(),
  };
}
}