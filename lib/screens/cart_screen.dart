import 'package:flutter/material.dart';

import '../models/product.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _coupon = TextEditingController();

  @override
  void dispose() {
    _coupon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final List<MapEntry<int, int>> lines = controller.cart.entries.toList();

    return MobileScaffold(
      appBar: const ScreenTitleBar(title: 'Shopping Cart'),
      body: lines.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_cart_outlined, size: 76),
                    const SizedBox(height: 16),
                    Text('Your cart is empty', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.catalog),
                      child: const Text('Browse Products'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
              children: [
                Text('${controller.cartCount} items', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 12),
                ...lines.map((entry) {
                  final Product product = controller.productById(entry.key);
                  final int quantity = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pushNamed(AppRoutes.productDetails, arguments: product),
                            child: ProductArt(product: product, size: 82),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.brand, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(product.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                                const SizedBox(height: 6),
                                Text(money(product.price), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 9),
                                Row(
                                  children: [
                                    QuantityStepper(
                                      value: quantity,
                                      onChanged: (value) => controller.setCartQuantity(product.id, value),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () => controller.removeFromCart(product.id),
                                      style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                                      child: const Text('Remove'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 4),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Coupon', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _coupon,
                              decoration: const InputDecoration(hintText: 'Enter SMILE10'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () {
                              final bool applied = controller.applyCoupon(_coupon.text);
                              showAppSnackBar(context, applied ? 'Coupon SMILE10 applied' : 'Invalid coupon code');
                            },
                            child: const Text('Apply'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _SummaryRow(label: 'Subtotal', value: money(controller.subtotal)),
                      _SummaryRow(label: 'Shipping', value: controller.shippingFee == 0 ? 'Free' : money(controller.shippingFee)),
                      _SummaryRow(label: 'Discount', value: controller.discount == 0 ? money(0) : '−${money(controller.discount)}', valueColor: AppColors.success),
                      const Divider(height: 24),
                      _SummaryRow(label: 'Total', value: money(controller.total), emphasized: true),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.checkout),
                        child: const Text('Proceed to Checkout'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.emphasized = false, this.valueColor});

  final String label;
  final String value;
  final bool emphasized;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = emphasized
        ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style?.copyWith(color: valueColor, fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700)),
        ],
      ),
    );
  }
}
