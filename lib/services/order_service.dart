import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static const List<String> orderStatuses = <String>[
    'Pending',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled',
  ];

  Future<User> _requireAdmin() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw StateError('You must log in first.');
    }

    final DocumentSnapshot<Map<String, dynamic>>
        userSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

    final String role =
        userSnapshot.data()?['role']
                ?.toString()
                .toLowerCase() ??
            '';

    if (role != 'admin') {
      throw StateError('Admin access required.');
    }

    return user;
  }

  Future<Map<String, String>> placeOrder({
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> shippingAddress,
    required String deliveryMethod,
    required String paymentMethod,
    required double subtotal,
    required double shippingFee,
    required double discount,
    required double total,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw StateError(
        'You must log in before placing an order.',
      );
    }

    if (items.isEmpty) {
      throw StateError('Your cart is empty.');
    }

    final DocumentReference<Map<String, dynamic>>
        orderReference =
        _firestore.collection('orders').doc();

    final String orderNumber =
        'SH-${orderReference.id.substring(0, 8).toUpperCase()}';

    await orderReference.set(
      <String, dynamic>{
        'orderId': orderReference.id,
        'orderNumber': orderNumber,
        'userId': user.uid,
        'customerEmail': user.email ?? '',
        'items': items,
        'itemCount': items.fold<int>(
          0,
          (
            int sum,
            Map<String, dynamic> item,
          ) {
            return sum +
                ((item['quantity'] as num?)
                        ?.toInt() ??
                    0);
          },
        ),
        'shippingAddress': shippingAddress,
        'deliveryMethod': deliveryMethod,
        'paymentMethod': paymentMethod,
        'subtotal': subtotal,
        'shippingFee': shippingFee,
        'discount': discount,
        'total': total,
        'status': 'Pending',
        'createdAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
    );

    return <String, String>{
      'orderId': orderReference.id,
      'orderNumber': orderNumber,
    };
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>
      watchMyOrders() {
    final User? user = _auth.currentUser;

    if (user == null) {
      return Stream<
          QuerySnapshot<Map<String, dynamic>>>.error(
        StateError('You must log in first.'),
      );
    }

    return _firestore
        .collection('orders')
        .where(
          'userId',
          isEqualTo: user.uid,
        )
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>
      watchAllOrders() async* {
    await _requireAdmin();

    yield* _firestore
        .collection('orders')
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await _requireAdmin();

    if (!orderStatuses.contains(status)) {
      throw ArgumentError(
        'Invalid order status: $status',
      );
    }

    final DocumentReference<Map<String, dynamic>>
        orderReference =
        _firestore
            .collection('orders')
            .doc(orderId);

    final DocumentSnapshot<Map<String, dynamic>>
        snapshot =
        await orderReference.get();

    if (!snapshot.exists) {
      throw StateError('Order not found.');
    }

    await orderReference.update(
      <String, dynamic>{
        'status': status,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
    );
  }
}