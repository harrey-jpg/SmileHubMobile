import 'package:flutter/material.dart';

import '../models/product.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

String money(num value) {
  final String digits = value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
  final List<String> parts = digits.split('.');
  final String whole = parts.first;
  final String grouped = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return parts.length == 2 ? '₱$grouped.${parts[1]}' : '₱$grouped';
}

class SmileHubLogo extends StatelessWidget {
  const SmileHubLogo({
    super.key,
    this.compact = false,
    this.centered = true,
  });

  final bool compact;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 34 : 58,
          height: compact ? 34 : 58,
          decoration: BoxDecoration(
            color: AppColors.teal,
            borderRadius: BorderRadius.circular(compact ? 10 : 17),
          ),
          child: Icon(
            Icons.health_and_safety_rounded,
            color: Colors.white,
            size: compact ? 20 : 34,
          ),
        ),
        SizedBox(width: compact ? 9 : 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SmileHub',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.aqua
                    : AppColors.teal,
                fontSize: compact ? 20 : 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
            if (!compact)
              Text(
                'Dental Supplies',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
          ],
        ),
      ],
    );

    return centered ? Center(child: content) : content;
  }
}

class MobileScaffold extends StatelessWidget {
  const MobileScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SizedBox.expand(child: body),
        ),
      ),
      bottomNavigationBar: bottomNavigationBar == null
          ? null
          : Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SizedBox(width: double.infinity, child: bottomNavigationBar),
              ),
            ),
    );
  }
}

class ScreenTitleBar extends StatelessWidget implements PreferredSizeWidget {
  const ScreenTitleBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.showBack = true,
  });

  final String title;
  final List<Widget> actions;
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      automaticallyImplyLeading: showBack,
      actions: actions,
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.subtitle,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            if (actionLabel != null)
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(18);
    return Material(
      color: color ?? Theme.of(context).colorScheme.surface,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.75),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class ProductArt extends StatelessWidget {
  const ProductArt({
    super.key,
    required this.product,
    this.size = 90,
  });

  final Product product;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF152744) : const Color(0xFFE9F1FF),
        borderRadius: BorderRadius.circular(size * 0.18),
      ),
      child: Icon(
        product.icon,
        size: size * 0.48,
        color: dark ? AppColors.aqua : AppColors.teal,
      ),
    );
  }
}

class ProductGridCard extends StatelessWidget {
  const ProductGridCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAdd,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);
    final bool saved = controller.wishlist.contains(product.id);

    return AppCard(
      padding: const EdgeInsets.all(10),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.35,
                child: SizedBox.expand(child: ProductArt(product: product, size: 120)),
              ),
              Positioned(
                right: 2,
                top: 2,
                child: IconButton.filledTonal(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => controller.toggleWishlist(product.id),
                  icon: Icon(saved ? Icons.favorite_rounded : Icons.favorite_border_rounded),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            product.brand,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  money(product.price),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton.filled(
                visualDensity: VisualDensity.compact,
                onPressed: onAdd,
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_rounded, size: 18),
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class CartBadgeIcon extends StatelessWidget {
  const CartBadgeIcon({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final int count = AppScope.of(context).cartCount;    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: const Icon(Icons.shopping_cart_outlined),
        ),
        if (count > 0)
          Positioned(
            right: 2,
            top: 1,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class WishlistBadgeIcon extends StatelessWidget {
  const WishlistBadgeIcon({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final int count = AppScope.of(context).wishlist.length;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: const Icon(Icons.favorite_border_rounded),
        ),
        if (count > 0)
          Positioned(
            right: 2,
            top: 1,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

void showAppSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class MainBottomNavigation extends StatelessWidget {
  const MainBottomNavigation({
    super.key,
    required this.currentIndex,
  });

  final int currentIndex;

  static const List<String> _routes = <String>[
    '/home',
    '/categories',
    '/wishlist',
    '/orders',
    '/account',
  ];

  @override
  Widget build(BuildContext context) {
    final int wishCount = AppScope.of(context).wishlist.length;
    Widget wishlistIcon = const Icon(Icons.favorite_border_rounded);
    Widget wishlistSelectedIcon = const Icon(Icons.favorite_rounded);
    if (wishCount > 0) {
      Badge badgeFor(IconData icon) =>
          Badge(label: Text('$wishCount'), child: Icon(icon));
      wishlistIcon = badgeFor(Icons.favorite_border_rounded);
      wishlistSelectedIcon = badgeFor(Icons.favorite_rounded);
    }
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        if (index == currentIndex) return;
        Navigator.of(context).pushNamed(_routes[index]);
      },
      destinations: [
        const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
        const NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view_rounded), label: 'Categories'),
        NavigationDestination(icon: wishlistIcon, selectedIcon: wishlistSelectedIcon, label: 'Wishlist'),
        const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded), label: 'Orders'),
        const NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
      ],
    );
  }
}
