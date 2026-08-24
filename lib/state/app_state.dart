import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/products.dart';
import '../models/product.dart';

class AppController extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.light;

  /// Live catalog. Starts with the bundled demo products and is replaced by
  /// the shared Firestore catalog once it loads.
  List<Product> products = List<Product>.from(smileHubProducts);

  final Set<int> wishlist = <int>{};
  final Map<int, int> cart = <int, int>{};

  bool couponApplied = false;
  int selectedAddressIndex = 0;
  int selectedPaymentIndex = 0;

  Future<void> loadProductsFromFirestore() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('products')
              .orderBy('id')
              .get();
      if (snapshot.docs.isEmpty) return;
      final List<Product> loaded = snapshot.docs.map((doc) {
        final Map<String, dynamic> d = doc.data();
        final String category =
            (d['category'] ?? 'General').toString();
        final int stock = (d['stock'] as num?)?.toInt() ?? 0;
        return Product(
          id: (d['id'] as num?)?.toInt() ?? 0,
          name: (d['name'] ?? 'Unnamed product').toString(),
          brand: (d['brand'] ?? '').toString(),
          category: category,
          price: ((d['price'] as num?) ?? 0).toDouble(),
          icon: iconForCategory(category),
          rating: ((d['rating'] as num?) ?? 4.5).toDouble(),
          stock: stock == 0
              ? 'Out of stock'
              : stock <= 10
                  ? 'Low stock'
                  : 'In stock',
          description: (d['description'] ?? '').toString(),
        );
      }).toList();
      if (loaded.isNotEmpty) {
        products = loaded;
        notifyListeners();
      }
    } catch (_) {
      // Offline or denied: keep the bundled fallback catalog.
    }
  }

  static IconData iconForCategory(String category) {
    switch (category) {
      case 'Oral Care':
        return Icons.cleaning_services_rounded;
      case 'Instruments':
        return Icons.construction_rounded;
      case 'PPE':
        return Icons.masks_rounded;
      case 'Restorative':
        return Icons.vaccines_rounded;
      case 'Disposables':
        return Icons.layers_rounded;
      case 'Impression':
        return Icons.view_in_ar_rounded;
      case 'Orthodontics':
        return Icons.radio_button_unchecked_rounded;
      case 'Equipment':
        return Icons.kitchen_rounded;
      default:
        return Icons.medical_services_rounded;
    }
  }

  final List<ShippingAddress> addresses = <ShippingAddress>[
    const ShippingAddress(
      label: 'Home',
      recipient: 'Juan Dela Cruz',
      phone: '0912 345 6789',
      address: '123 Smile Street, Barangay Central, Quezon City, Metro Manila 1100',
      isDefault: true,
    ),
    const ShippingAddress(
      label: 'Clinic',
      recipient: 'Juan Dela Cruz',
      phone: '0912 345 6789',
      address: 'Smile Dental Clinic, 28 Health Avenue, Makati City, Metro Manila 1200',
    ),
  ];

  final List<PaymentMethodItem> paymentMethods = <PaymentMethodItem>[
    const PaymentMethodItem(
      title: 'Cash on Delivery',
      subtitle: 'Pay when your order arrives',
      icon: Icons.payments_rounded,
      isDefault: true,
    ),
    const PaymentMethodItem(
      title: 'GCash',
      subtitle: '•••• •••• 6789',
      icon: Icons.account_balance_wallet_rounded,
    ),
    const PaymentMethodItem(
      title: 'Visa ending 1234',
      subtitle: 'Expires 08/29',
      icon: Icons.credit_card_rounded,
    ),
  ];

  bool get isDarkMode => themeMode == ThemeMode.dark;

  Product productById(int id) {
    return products.firstWhere(
      (product) => product.id == id,
      orElse: () => products.isNotEmpty ? products.first : smileHubProducts.first,
    );
  }

  int quantityFor(int productId) => cart[productId] ?? 0;

  int get cartCount => cart.values.fold<int>(0, (sum, quantity) => sum + quantity);

  double get subtotal {
    return cart.entries.fold<double>(0, (sum, entry) {
      return sum + productById(entry.key).price * entry.value;
    });
  }

  double get shippingFee => subtotal >= 3000 || cart.isEmpty ? 0 : 120;

  double get discount => couponApplied ? (subtotal * 0.10).clamp(0, 349.90).toDouble() : 0;

  double get total => subtotal + shippingFee - discount;

  ShippingAddress get selectedAddress => addresses[selectedAddressIndex.clamp(0, addresses.length - 1).toInt()];

  PaymentMethodItem get selectedPayment => paymentMethods[selectedPaymentIndex.clamp(0, paymentMethods.length - 1).toInt()];

  void toggleTheme([bool? enabled]) {
    final bool turnDark = enabled ?? !isDarkMode;
    themeMode = turnDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void toggleWishlist(int productId) {
    if (!wishlist.add(productId)) {
      wishlist.remove(productId);
    }
    notifyListeners();
  }

  void addToCart(int productId, {int quantity = 1}) {
    cart.update(productId, (current) => current + quantity, ifAbsent: () => quantity);
    notifyListeners();
  }

  void setCartQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      cart.remove(productId);
    } else {
      cart[productId] = quantity;
    }
    notifyListeners();
  }

  void removeFromCart(int productId) {
    cart.remove(productId);
    notifyListeners();
  }

  bool applyCoupon(String code) {
    couponApplied = code.trim().toUpperCase() == 'SMILE10';
    notifyListeners();
    return couponApplied;
  }

  void selectAddress(int index) {
    selectedAddressIndex = index;
    notifyListeners();
  }

  void addAddress(ShippingAddress address) {
    addresses.add(address);
    selectedAddressIndex = addresses.length - 1;
    notifyListeners();
  }

  void selectPayment(int index) {
    selectedPaymentIndex = index;
    notifyListeners();
  }

  void addPaymentMethod(PaymentMethodItem method) {
    paymentMethods.add(method);
    selectedPaymentIndex = paymentMethods.length - 1;
    notifyListeners();
  }

  void clearCartAfterOrder() {
    cart.clear();
    couponApplied = false;
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final AppScope? scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope was not found above this context.');
    return scope!.notifier!;
  }

  static AppController read(BuildContext context) {
    final AppScope? scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope was not found above this context.');
    return scope!.notifier!;
  }
}
