import 'package:flutter/material.dart';

import '../data/products.dart';
import '../models/product.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../widgets/app_widgets.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final List<Product> items = smileHubProducts.where((product) => controller.wishlist.contains(product.id)).toList();

    return MobileScaffold(
      appBar: ScreenTitleBar(
        title: 'Wishlist',
        showBack: false,
        actions: [CartBadgeIcon(onPressed: () => Navigator.of(context).pushNamed(AppRoutes.cart))],
      ),
      bottomNavigationBar: const MainBottomNavigation(currentIndex: 2),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite_border_rounded, size: 74),
                    const SizedBox(height: 16),
                    Text('No saved products yet', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.catalog),
                      child: const Text('Browse Products'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final Product product = items[index];
                return AppCard(
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.productDetails, arguments: product),
                  child: Row(
                    children: [
                      ProductArt(product: product, size: 82),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.brand, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 3),
                            Text(product.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 7),
                            Text(money(product.price), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 10),
                            FilledButton.tonalIcon(
                              onPressed: () {
                                controller.addToCart(product.id);
                                showAppSnackBar(context, '${product.name} added to cart');
                              },
                              icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                              label: const Text('Add to Cart'),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => controller.toggleWishlist(product.id),
                        icon: const Icon(Icons.favorite_rounded),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
