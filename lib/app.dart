import 'package:flutter/material.dart';

import 'models/product.dart';
import 'routes.dart';
import 'screens/account_screen.dart';
import 'screens/add_address_screen.dart';
import 'screens/add_payment_screen.dart';
import 'screens/addresses_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/catalog_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/contact_support_screen.dart';
import 'screens/help_support_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/order_details_screen.dart';
import 'screens/order_success_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/payments_screen.dart';
import 'screens/personal_information_screen.dart';
import 'screens/product_details_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/wishlist_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

class SmileHubApp extends StatefulWidget {
  const SmileHubApp({super.key});

  @override
  State<SmileHubApp> createState() => _SmileHubAppState();
}

class _SmileHubAppState extends State<SmileHubApp> {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SmileHub Dental Supplies',
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: _controller.themeMode,
          builder: (context, child) {
            return AppScope(
              controller: _controller,
              child: child ?? const SizedBox.shrink(),
            );
          },
          initialRoute: AppRoutes.onboarding,
          onGenerateRoute: _onGenerateRoute,
        );
      },
    );
  }

  Route<dynamic> _onGenerateRoute(
    RouteSettings settings,
  ) {
    final Object? arguments = settings.arguments;

    late final Widget page;

    if (settings.name == AppRoutes.onboarding) {
      page = const OnboardingScreen();
    } else if (settings.name == AppRoutes.login) {
      page = const LoginScreen();
    } else if (settings.name == AppRoutes.signup) {
      page = const SignUpScreen();
    } else if (settings.name == AppRoutes.home) {
      page = const HomeScreen();
    } else if (settings.name == AppRoutes.categories) {
      page = const CategoriesScreen();
    } else if (settings.name == AppRoutes.catalog) {
      page = CatalogScreen(
        initialCategory:
            arguments is String ? arguments : 'All',
      );
    } else if (settings.name == AppRoutes.productDetails) {
      final Product product = arguments is Product
          ? arguments
          : _controller.productById(29);

      page = ProductDetailsScreen(
        product: product,
      );
    } else if (settings.name == AppRoutes.wishlist) {
      page = const WishlistScreen();
    } else if (settings.name == AppRoutes.cart) {
      page = const CartScreen();
    } else if (settings.name == AppRoutes.checkout) {
      // BUY NOW
      if (arguments is Map &&
          arguments['productId'] is int) {
        page = CheckoutScreen(
          buyNowProductId:
              arguments['productId'] as int,
          buyNowQuantity:
              arguments['quantity'] is int
                  ? arguments['quantity'] as int
                  : 1,
        );
      } else {
        // NORMAL CART CHECKOUT
        page = const CheckoutScreen();
      }
    } else if (settings.name == AppRoutes.orderSuccess) {
      page = const OrderSuccessScreen();
    } else if (settings.name == AppRoutes.orders) {
      page = const OrdersScreen();
    } else if (settings.name == AppRoutes.orderDetails) {
      if (arguments is Map &&
          arguments['orderData'] is Map) {
        page = OrderDetailsScreen(
          orderId:
              arguments['orderId']?.toString() ?? '',
          orderData: Map<String, dynamic>.from(
            arguments['orderData'] as Map,
          ),
        );
      } else {
        page = const OrdersScreen();
      }
    } else if (settings.name == AppRoutes.account) {
      page = const AccountScreen();
    } else if (
        settings.name ==
        AppRoutes.personalInformation) {
      page = const PersonalInformationScreen();
    } else if (settings.name == AppRoutes.addresses) {
      page = AddressesScreen(
        selectionMode: arguments == true,
      );
    } else if (settings.name == AppRoutes.addAddress) {
      page = const AddAddressScreen();
    } else if (settings.name == AppRoutes.payments) {
      page = PaymentsScreen(
        selectionMode: arguments == true,
      );
    } else if (settings.name == AppRoutes.addPayment) {
      page = const AddPaymentScreen();
    } else if (settings.name == AppRoutes.help) {
      page = const HelpSupportScreen();
    } else if (
        settings.name ==
        AppRoutes.contactSupport) {
      page = ContactSupportScreen(
        initialConcern: arguments is String
            ? arguments
            : 'Order concern',
      );
    } else {
      page = const OnboardingScreen();
    }

    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (_) => page,
    );
  }
}