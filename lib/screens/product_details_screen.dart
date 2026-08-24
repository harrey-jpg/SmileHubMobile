import 'package:flutter/material.dart';

import '../models/product.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final Product product = widget.product;
    final AppController controller = AppScope.of(context);
    final bool saved = controller.wishlist.contains(product.id);

    return MobileScaffold(
      appBar: ScreenTitleBar(
        title: 'Product Details',
        actions: [
          IconButton(
            onPressed: () => controller.toggleWishlist(product.id),
            icon: Icon(saved ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: saved ? AppColors.danger : null),
          ),
          CartBadgeIcon(onPressed: () => Navigator.of(context).pushNamed(AppRoutes.cart)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(aspectRatio: 1.25, child: ProductArt(product: product, size: 220)),
            const SizedBox(height: 22),
            Text(product.brand, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text(product.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber),
                Text('${product.rating} (126 reviews)', style: const TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                Chip(label: Text(product.stock)),
              ],
            ),
            const SizedBox(height: 12),
            Text(money(product.price), style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            Text(product.description, style: TextStyle(height: 1.55, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 22),
            Row(
              children: [
                const Expanded(child: Text('Quantity', style: TextStyle(fontWeight: FontWeight.w900))),
                QuantityStepper(value: _quantity, onChanged: (value) => setState(() => _quantity = value)),
              ],
            ),
            const SizedBox(height: 18),
            AppCard(
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF123A4C) : const Color(0xFFDFF7FA),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✓ Quality checked', style: TextStyle(fontWeight: FontWeight.w800)),
                  SizedBox(height: 6),
                  Text('✓ Local delivery available', style: TextStyle(fontWeight: FontWeight.w800)),
                  SizedBox(height: 6),
                  Text('✓ Secure checkout', style: TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 20),
ElevatedButton.icon(
  onPressed: () {
    controller.addToCart(
      product.id,
      quantity: _quantity,
    );

    showAppSnackBar(
      context,
      '${product.name} added to cart',
    );
  },
  icon: const Icon(
    Icons.add_shopping_cart_rounded,
  ),
  label: const Text('Add to Cart'),
),

const SizedBox(height: 12),

FilledButton.icon(
  onPressed: () {
    Navigator.of(context).pushNamed(
      AppRoutes.checkout,
      arguments: <String, dynamic>{
        'productId': product.id,
        'quantity': _quantity,
      },
    );
  },
  icon: const Icon(
    Icons.shopping_bag_rounded,
  ),
  label: const Text('Buy Now'),
),

const SizedBox(height: 12),

OutlinedButton.icon(
              onPressed: () => controller.toggleWishlist(product.id),
              icon: Icon(saved ? Icons.favorite_rounded : Icons.favorite_border_rounded),
              label: Text(saved ? 'Remove from Wishlist' : 'Save to Wishlist'),
            ),
          ],
        ),
      ),
    );
  }
}
