import 'package:flutter/material.dart';

import '../data/products.dart';
import '../models/product.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../widgets/app_widgets.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key, this.initialCategory = 'All'});

  final String initialCategory;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late String _category;
  String _query = '';
  String _sort = 'Featured';

  @override
  void initState() {
    super.initState();
    _category = productCategories.contains(widget.initialCategory) ? widget.initialCategory : 'All';
  }

  List<Product> get _filtered {
    final String normalized = _query.trim().toLowerCase();
    final List<Product> result = smileHubProducts.where((product) {
      final bool categoryMatch = _category == 'All' || product.category == _category;
      final bool searchMatch = normalized.isEmpty || product.name.toLowerCase().contains(normalized) || product.brand.toLowerCase().contains(normalized);
      return categoryMatch && searchMatch;
    }).toList();

    switch (_sort) {
      case 'Price: Low':
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: High':
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Rating':
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      default:
        break;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final List<Product> products = _filtered;

    return MobileScaffold(
      appBar: ScreenTitleBar(
        title: 'Product Catalog',
        actions: [
          WishlistBadgeIcon(onPressed: () => Navigator.of(context).pushNamed(AppRoutes.wishlist)),
          CartBadgeIcon(onPressed: () => Navigator.of(context).pushNamed(AppRoutes.cart)),
        ],
      ),
      bottomNavigationBar: const MainBottomNavigation(currentIndex: 1),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: const InputDecoration(hintText: 'Product or brand', prefixIcon: Icon(Icons.search_rounded)),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: productCategories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final String category = productCategories[index];
                        return ChoiceChip(
                          label: Text(category),
                          selected: _category == category,
                          onSelected: (_) => setState(() => _category = category),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: Text('${products.length} products found', style: const TextStyle(fontWeight: FontWeight.w800))),
                      DropdownButton<String>(
                        value: _sort,
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(value: 'Featured', child: Text('Featured')),
                          DropdownMenuItem(value: 'Price: Low', child: Text('Price: Low')),
                          DropdownMenuItem(value: 'Price: High', child: Text('Price: High')),
                          DropdownMenuItem(value: 'Rating', child: Text('Rating')),
                        ],
                        onChanged: (value) => setState(() => _sort = value ?? 'Featured'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (products.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('No products found.')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final Product product = products[index];
                    return ProductGridCard(
                      product: product,
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.productDetails, arguments: product),
                      onAdd: () {
                        controller.addToCart(product.id);
                        showAppSnackBar(context, '${product.name} added to cart');
                      },
                    );
                  },
                  childCount: products.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.69,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
