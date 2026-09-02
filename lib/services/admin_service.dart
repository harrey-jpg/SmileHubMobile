import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const List<String> adminRoles = <String>[
    'admin',
    'staff',
    'superadmin',
  ];

  /// Returns the role string in lower-case, or null if not signed in / not found.
  Future<String?> getCurrentUserRole() async {
    final User? user = _auth.currentUser;
    if (user == null) return null;
    try {
      final DocumentSnapshot<Map<String, dynamic>> snap =
          await _firestore.collection('users').doc(user.uid).get();
      final String? role = snap.data()?['role']?.toString().toLowerCase();
      return role;
    } catch (_) {
      return null;
    }
  }

  Future<bool> isAdmin() async {
    final String? role = await getCurrentUserRole();
    return role != null && adminRoles.contains(role);
  }

  Future<bool> isSuperAdmin() async {
    final String? role = await getCurrentUserRole();
    return role == 'superadmin';
  }

  Future<void> requireAdmin() async {
    final bool ok = await isAdmin();
    if (!ok) throw StateError('Admin access required.');
  }

  Future<void> requireSuperAdmin() async {
    final bool ok = await isSuperAdmin();
    if (!ok) throw StateError('Super admin access required.');
  }

  // ---------------------------------------------------------------------------
  // Products
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getProductsRaw() async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _firestore
        .collection('products')
        .orderBy('id')
        .get();
    return snap.docs.map((d) => <String, dynamic>{'docId': d.id, ...d.data()}).toList();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchProductsRaw() {
    return _firestore.collection('products').orderBy('id').snapshots();
  }

  Future<void> updateProductStock({
    required int productId,
    required int newStock,
  }) async {
    await requireAdmin();
    if (newStock < 0) throw ArgumentError('Stock cannot be negative.');
    final String docId = productId.toString();
    final DocumentReference<Map<String, dynamic>> ref =
        _firestore.collection('products').doc(docId);

    // Some deployments may have seeded products under non-numeric ids; try
    // fetching first to decide whether to create or update.
    final DocumentSnapshot<Map<String, dynamic>> existing = await ref.get();
    final String status =
        newStock == 0 ? 'Out of Stock' : newStock <= 10 ? 'Low Stock' : 'Active';

    if (!existing.exists) {
      // Create a minimal document so the catalog stays consistent.
      await ref.set(<String, dynamic>{
        'id': productId,
        'stock': newStock,
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      await ref.update(<String, dynamic>{
        'stock': newStock,
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // Bump products_meta version — mirrors web's saveProducts behaviour.
    try {
      await _firestore.collection('products_meta').doc('latest').set(
        <String, dynamic>{
          'version': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Non-fatal: meta update requires admin but primary stock update already succeeded.
    }
  }

  // ---------------------------------------------------------------------------
  // Accounts — mirrors web's getAccounts() merge logic
  // ---------------------------------------------------------------------------
  /// Fetches merged accounts from `accounts` + `users`, excluding `deleted_accounts`.
  Future<List<Map<String, dynamic>>> getAccounts() async {
    await requireAdmin();

    final QuerySnapshot<Map<String, dynamic>> accountsSnap =
        await _firestore.collection('accounts').get();
    final QuerySnapshot<Map<String, dynamic>> usersSnap =
        await _firestore.collection('users').get();
    QuerySnapshot<Map<String, dynamic>>? deletedSnap;
    try {
      deletedSnap = await _firestore.collection('deleted_accounts').get();
    } catch (_) {
      deletedSnap = null;
    }

    final Set<String> deletedSet = <String>{};
    if (deletedSnap != null) {
      for (final d in deletedSnap.docs) {
        deletedSet.add(d.id.toLowerCase());
        final dynamic email = d.data()['email'];
        if (email is String) deletedSet.add(email.toLowerCase());
      }
    }

    final Map<String, Map<String, dynamic>> byEmail = <String, Map<String, dynamic>>{};

    for (final doc in accountsSnap.docs) {
      final Map<String, dynamic> a = doc.data();
      final String? email = a['email']?.toString();
      if (email == null || email.isEmpty) continue;
      final String lower = email.toLowerCase();
      if (deletedSet.contains(lower) || deletedSet.contains(doc.id.toLowerCase())) continue;
      byEmail[lower] = Map<String, dynamic>.from(a);
    }

    for (final doc in usersSnap.docs) {
      final Map<String, dynamic> u = doc.data();
      final String email = (u['email'] ?? '').toString().toLowerCase();
      if (email.isEmpty || deletedSet.contains(email)) continue;
      final String displayName = (u['displayName'] ?? '').toString().trim().isNotEmpty
          ? u['displayName'].toString()
          : ([u['firstName'], u['lastName']].where((e) => e != null && e.toString().trim().isNotEmpty).join(' ').trim().isNotEmpty
              ? [u['firstName'], u['lastName']].where((e) => e != null && e.toString().trim().isNotEmpty).join(' ')
              : (u['fullName'] ?? email).toString());

      if (!byEmail.containsKey(email)) {
        byEmail[email] = <String, dynamic>{
          'name': displayName,
          'email': email,
          'role': (u['role'] ?? 'customer').toString().toLowerCase(),
          'status': 'active',
          'firstName': u['firstName'] ?? '',
          'lastName': u['lastName'] ?? '',
          'uid': doc.id,
        };
      } else {
        final Map<String, dynamic> existing = byEmail[email]!;
        if ((existing['name'] == null || existing['name'].toString().trim().isEmpty || existing['name'] == email) &&
            displayName.isNotEmpty) {
          existing['name'] = displayName;
        }
        final String uRole = (u['role'] ?? '').toString().toLowerCase();
        final String existingRole = (existing['role'] ?? 'customer').toString().toLowerCase();
        if (uRole.isNotEmpty && (existingRole == 'customer' || existingRole.isEmpty)) {
          existing['role'] = uRole;
        }
        if (existing['uid'] == null) existing['uid'] = doc.id;
      }
    }

    final List<Map<String, dynamic>> accounts = byEmail.values
        .map((m) => <String, dynamic>{
              'name': (m['name'] ?? m['email'] ?? '').toString(),
              'email': (m['email'] ?? '').toString().toLowerCase(),
              'role': (m['role'] ?? 'customer').toString().toLowerCase(),
              'status': (m['status'] ?? 'active').toString().toLowerCase(),
              'firstName': (m['firstName'] ?? '').toString(),
              'lastName': (m['lastName'] ?? '').toString(),
              if (m['uid'] != null) 'uid': m['uid'],
            })
        .toList();

    accounts.sort((a, b) => (a['email'] as String).compareTo(b['email'] as String));
    return accounts;
  }

  Future<void> updateAccountRole({
    required String email,
    required String newRole,
  }) async {
    await requireSuperAdmin();
    final String lower = email.trim().toLowerCase();
    final String role = newRole.trim().toLowerCase();
    if (!<String>['customer', 'staff', 'admin', 'superadmin'].contains(role)) {
      throw ArgumentError('Invalid role: $newRole');
    }

    // Update accounts/{email} (canonical id is lower-case email; try both cases for compatibility)
    final DocumentReference<Map<String, dynamic>> accRef =
        _firestore.collection('accounts').doc(lower);
    final DocumentSnapshot<Map<String, dynamic>> accSnap = await accRef.get();
    if (accSnap.exists) {
      await accRef.set(<String, dynamic>{'role': role}, SetOptions(merge: true));
    } else {
      // Fallback: original case
      final DocumentReference<Map<String, dynamic>> accRef2 =
          _firestore.collection('accounts').doc(email.trim());
      final DocumentSnapshot<Map<String, dynamic>> accSnap2 = await accRef2.get();
      if (accSnap2.exists) {
        await accRef2.set(<String, dynamic>{'role': role}, SetOptions(merge: true));
      } else {
        // Create missing account entry
        await accRef.set(<String, dynamic>{
          'email': lower,
          'role': role,
          'status': 'active',
        }, SetOptions(merge: true));
      }
    }

    // Mirror to users collection — find by email and update role
    final QuerySnapshot<Map<String, dynamic>> usersByEmail = await _firestore
        .collection('users')
        .where('email', isEqualTo: lower)
        .get();
    if (usersByEmail.docs.isNotEmpty) {
      for (final d in usersByEmail.docs) {
        await d.reference.set(<String, dynamic>{'role': role}, SetOptions(merge: true));
      }
    } else {
      // Try original-case email as well
      final QuerySnapshot<Map<String, dynamic>> usersByEmail2 = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .get();
      for (final d in usersByEmail2.docs) {
        await d.reference.set(<String, dynamic>{'role': role}, SetOptions(merge: true));
      }
    }
  }

  Future<void> toggleAccountStatus({
    required String email,
    required String newStatus,
  }) async {
    await requireAdmin();
    final String lower = email.trim().toLowerCase();
    final String status = newStatus.trim().toLowerCase();
    if (!<String>['active', 'suspended'].contains(status)) {
      throw ArgumentError('Invalid status: $newStatus');
    }

    final DocumentReference<Map<String, dynamic>> accRef =
        _firestore.collection('accounts').doc(lower);
    final DocumentSnapshot<Map<String, dynamic>> snap = await accRef.get();
    if (snap.exists) {
      await accRef.set(<String, dynamic>{'status': status}, SetOptions(merge: true));
    } else {
      final DocumentReference<Map<String, dynamic>> accRef2 =
          _firestore.collection('accounts').doc(email.trim());
      final DocumentSnapshot<Map<String, dynamic>> snap2 = await accRef2.get();
      if (snap2.exists) {
        await accRef2.set(<String, dynamic>{'status': status}, SetOptions(merge: true));
      } else {
        await accRef.set(<String, dynamic>{
          'email': lower,
          'status': status,
          'role': 'customer',
        }, SetOptions(merge: true));
      }
    }
  }
}


