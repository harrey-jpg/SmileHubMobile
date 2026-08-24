import 'package:flutter/material.dart';

import '../data/products.dart';
import '../models/product.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final List<Product> featured =
        controller.products.where((p) => <int>{1, 5, 9, 29}.contains(p.id)).toList();
    final int skip = controller.products.length > 6 ? controller.products.length - 6 : 0;
    final List<Product> latest = controller.products.skip(skip).take(6).toList();

    return MobileScaffold(
      bottomNavigationBar: const MainBottomNavigation(currentIndex: 0),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 14),
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF0D5F72)
                    : AppColors.teal,
                child: const Text(
                  'Free shipping on orders over ₱3,000 • Metro Manila',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  Row(
                    children: [
                      const Expanded(child: SmileHubLogo(compact: true, centered: false)),
                      WishlistBadgeIcon(onPressed: () => Navigator.of(context).pushNamed(AppRoutes.wishlist)),
                      CartBadgeIcon(onPressed: () => Navigator.of(context).pushNamed(AppRoutes.cart)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    readOnly: true,
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.catalog),
                    decoration: const InputDecoration(
                      hintText: 'Search dental products...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _HeroBanner(
                    onShop: () => Navigator.of(context).pushNamed(AppRoutes.catalog),
                  ),
                  const SizedBox(height: 20),
                  SectionHeader(
                    title: 'Popular Categories',
                    actionLabel: 'View all',
                    onAction: () => Navigator.of(context).pushNamed(AppRoutes.categories),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 92,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: const [
                        _CategoryBubble(label: 'Oral Care', icon: Icons.cleaning_services_rounded, routeCategory: 'Oral Care'),
                        _CategoryBubble(label: 'Instruments', icon: Icons.construction_rounded, routeCategory: 'Instruments'),
                        _CategoryBubble(label: 'PPE', icon: Icons.masks_rounded, routeCategory: 'PPE'),
                        _CategoryBubble(label: 'Equipment', icon: Icons.medical_services_rounded, routeCategory: 'Equipment'),
                        _CategoryBubble(label: 'Impression', icon: Icons.sentiment_satisfied_alt_rounded, routeCategory: 'Impression'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppCard(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF0D5F72)
                        : AppColors.teal,
                    padding: const EdgeInsets.all(18),
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.catalog),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Clinic Starter Sale', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                              SizedBox(height: 5),
                              Text('Use coupon SMILE10 for 10% off', style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ),
                        FilledButton.tonal(
                          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.catalog),
                          child: const Text('View deals'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  SectionHeader(
                    title: 'Featured Products',
                    actionLabel: 'See all',
                    onAction: () => Navigator.of(context).pushNamed(AppRoutes.catalog),
                  ),
                  const SizedBox(height: 10),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = featured[index];
                    return ProductGridCard(
                      product: product,
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.productDetails, arguments: product),
                      onAdd: () {
                        controller.addToCart(product.id);
                        showAppSnackBar(context, '${product.name} added to cart');
                      },
                    );
                  },
                  childCount: featured.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.69,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
              sliver: SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Latest Products',
                  subtitle: 'Fresh supplies added to SmileHub',
                  actionLabel: 'Browse',
                  onAction: () => Navigator.of(context).pushNamed(AppRoutes.catalog),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: latest.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final product = latest[index];
                  return AppCard(
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.productDetails, arguments: product),
                    child: Row(
                      children: [
                        ProductArt(product: product, size: 76),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.brand, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 6),
                              Text(money(product.price), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: () {
                            controller.addToCart(product.id);
                            showAppSnackBar(context, '${product.name} added to cart');
                          },
                          icon: const Icon(Icons.add_shopping_cart_rounded),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Why clinics choose SmileHub'),
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        Expanded(child: _TrustItem(icon: Icons.verified_user_rounded, title: 'Quality checked', caption: 'Reliable clinic essentials')),
                        SizedBox(width: 10),
                        Expanded(child: _TrustItem(icon: Icons.local_shipping_rounded, title: 'Local delivery', caption: 'Convenient Metro Manila shipping')),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        Expanded(child: _TrustItem(icon: Icons.lock_rounded, title: 'Secure checkout', caption: 'Protected payment options')),
                        SizedBox(width: 10),
                        Expanded(child: _TrustItem(icon: Icons.support_agent_rounded, title: 'Helpful support', caption: 'Order and product assistance')),
                      ],
                    ),
                    const SizedBox(height: 22),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(child: Icon(Icons.person_rounded)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Dr. Mia Santos', style: TextStyle(fontWeight: FontWeight.w900)),
                                    Text('Verified clinic buyer', style: Theme.of(context).textTheme.bodySmall),
                                  ],
                                ),
                              ),
                              const Row(children: [Icon(Icons.star_rounded, color: Colors.amber, size: 18), Text('4.9')]),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text('“The catalog is easy to browse, and the clinic essentials arrive well packed.”'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text('Trusted brands', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        Chip(label: Text('SmilePro')),
                        Chip(label: Text('Clinix')),
                        Chip(label: Text('SafeTouch')),
                        Chip(label: Text('Restora')),
                        Chip(label: Text('Impressa')),
                        Chip(label: Text('LumaDent')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onShop});

  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF122643) : const Color(0xFFEAF0FF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trusted Dental Marketplace', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Better supplies\nfor brighter smiles.', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, height: 1.05)),
                const SizedBox(height: 8),
                Text('Clinic essentials, all in one hub.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 14),
                FilledButton(onPressed: onShop, child: const Text('Shop Products')),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 92,
            height: 118,
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF173151) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.teal, width: 2),
            ),
            child: const Icon(Icons.medical_services_rounded, size: 55, color: AppColors.teal),
          ),
        ],
      ),
    );
  }
}

class _CategoryBubble extends StatelessWidget {
  const _CategoryBubble({required this.label, required this.icon, required this.routeCategory});

  final String label;
  final IconData icon;
  final String routeCategory;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).pushNamed(AppRoutes.catalog, arguments: routeCategory),
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF152744) : const Color(0xFFE7F5FA),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 6),
              Text(label, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.title, required this.caption});

  final IconData icon;
  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(caption, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
