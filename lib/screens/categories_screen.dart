import 'package:flutter/material.dart';

import '../routes.dart';
import '../widgets/app_widgets.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  static const List<_CategoryData> categories = [
    _CategoryData('Oral Care', 'Toothbrushes, floss, toothpaste', Icons.cleaning_services_rounded),
    _CategoryData('Instruments', 'Mirrors, explorers, scalers', Icons.construction_rounded),
    _CategoryData('PPE', 'Gloves, masks, face shields', Icons.masks_rounded),
    _CategoryData('Restorative', 'Composite, bonding, cements', Icons.science_rounded),
    _CategoryData('Disposables', 'Bibs, syringes, microbrushes', Icons.inventory_2_rounded),
    _CategoryData('Impression', 'Alginate and VPS materials', Icons.sentiment_satisfied_alt_rounded),
    _CategoryData('Orthodontics', 'Wax, elastics, accessories', Icons.radio_button_unchecked_rounded),
    _CategoryData('Equipment', 'Curing lights, scalers, autoclaves', Icons.medical_services_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return MobileScaffold(
      appBar: ScreenTitleBar(
        title: 'Categories',
        showBack: false,
        actions: [
          IconButton(onPressed: () => Navigator.of(context).pushNamed(AppRoutes.wishlist), icon: const Icon(Icons.favorite_border_rounded)),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    readOnly: true,
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.catalog),
                    decoration: const InputDecoration(hintText: 'Search categories...', prefixIcon: Icon(Icons.search_rounded)),
                  ),
                  const SizedBox(height: 18),
                  Text('Popular Dental Categories', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('Quick access to products clinics and students use most.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = categories[index];
                  return AppCard(
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.catalog, arguments: category.name),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(category.icon, color: Theme.of(context).colorScheme.primary),
                        ),
                        const Spacer(),
                        Text(category.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(category.caption, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  );
                },
                childCount: categories.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.04,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryData {
  const _CategoryData(this.name, this.caption, this.icon);

  final String name;
  final String caption;
  final IconData icon;
}
