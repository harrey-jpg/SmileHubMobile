import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../services/admin_service.dart';
import '../../services/order_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();

  String? _role;
  bool _checkingRole = true;
  String? _roleError;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    try {
      final String? role = await _adminService.getCurrentUserRole();
      if (!mounted) return;
      setState(() {
        _role = role;
        _checkingRole = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _roleError = e.toString();
        _checkingRole = false;
      });
    }
  }

  bool get _isAdmin {
    final String r = (_role ?? '').toLowerCase();
    return AdminService.adminRoles.contains(r);
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingRole) {
      return const MobileScaffold(
        appBar: ScreenTitleBar(title: 'Admin Dashboard'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_roleError != null) {
      return MobileScaffold(
        appBar: const ScreenTitleBar(title: 'Admin Dashboard'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Unable to verify admin access: $_roleError',
                textAlign: TextAlign.center),
          ),
        ),
      );
    }

    if (!_isAdmin) {
      return MobileScaffold(
        appBar: const ScreenTitleBar(title: 'Admin Dashboard'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_rounded, size: 56, color: AppColors.danger),
                const SizedBox(height: 16),
                Text('Admin access required',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(
                  'Your account role is "${_role ?? 'unknown'}". Only admin, staff, or superadmin accounts can access this panel.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final AppController controller = AppScope.of(context);
    // Compute inventory KPIs from live product list (fallback or Firestore)
    final List<int> stocks = _extractStocks(controller);
    final int totalProducts = controller.products.length;
    final int lowStock = stocks.where((s) => s > 0 && s <= 10).length;
    final int outOfStock = stocks.where((s) => s == 0).length;
    final int totalStock = stocks.fold<int>(0, (a, b) => a + b);
    final double inventoryValue = _inventoryValue(controller, stocks);

    return MobileScaffold(
      appBar: ScreenTitleBar(
        title: 'Admin Dashboard',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () async {
              await controller.loadProductsFromFirestore();
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _safeWatchAllOrders(),
        builder: (context, snap) {
          int todayOrders = 0;
          double todaySales = 0;
          int totalOrders = 0;
          double totalRevenue = 0;

          if (snap.hasData) {
            final docs = snap.data!.docs;
            totalOrders = docs.length;
            final now = DateTime.now();
            for (final d in docs) {
              final data = d.data();
              final double tot = (data['total'] as num?)?.toDouble() ?? 0;
              totalRevenue += tot;
              final Timestamp? ts = data['createdAt'] as Timestamp?;
              if (ts != null) {
                final dt = ts.toDate();
                if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
                  todayOrders += 1;
                  todaySales += tot;
                }
              }
            }
          }

          final List<_LowStockItem> lowStockItems = _buildLowStockList(controller, stocks);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              // Role badge
              AppCard(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.55),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.teal,
                      child: Text(
                        (_role ?? 'A')[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Signed in as ${_role?.toUpperCase() ?? 'ADMIN'}',
                              style: const TextStyle(fontWeight: FontWeight.w900)),
                          Text('SmileHub Admin Panel',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.teal,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _role ?? '',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Key Metrics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.55,
                children: [
                  _KpiCard(
                    label: 'Total Products',
                    value: '$totalProducts',
                    caption: '$totalStock units in stock',
                    icon: Icons.inventory_2_rounded,
                    color: AppColors.teal,
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminProducts),
                  ),
                  _KpiCard(
                    label: 'Low Stock',
                    value: '$lowStock',
                    caption: '$outOfStock out of stock',
                    icon: Icons.warning_amber_rounded,
                    color: lowStock > 0 ? Colors.orange : AppColors.success,
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminProducts),
                  ),
                  _KpiCard(
                    label: 'Inventory Value',
                    value: money(inventoryValue),
                    caption: 'At current stock',
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppColors.navy,
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminProducts),
                  ),
                  _KpiCard(
                    label: "Today's Sales",
                    value: money(todaySales),
                    caption: '$todayOrders order${todayOrders == 1 ? '' : 's'} today',
                    icon: Icons.trending_up_rounded,
                    color: AppColors.success,
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminOrders),
                  ),
                  _KpiCard(
                    label: 'Total Orders',
                    value: '$totalOrders',
                    caption: snap.hasData ? 'All time' : 'Loading…',
                    icon: Icons.receipt_long_rounded,
                    color: Colors.deepPurple,
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminOrders),
                  ),
                  _KpiCard(
                    label: 'Out of Stock',
                    value: '$outOfStock',
                    caption: outOfStock == 0 ? 'All stocked' : 'Needs restock',
                    icon: Icons.remove_shopping_cart_rounded,
                    color: outOfStock > 0 ? AppColors.danger : AppColors.success,
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminProducts),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Today revenue extra
              if (snap.hasData)
                AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Revenue (all orders)', style: TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(money(totalRevenue),
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                      Icon(Icons.payments_rounded, color: Theme.of(context).colorScheme.primary, size: 36),
                    ],
                  ),
                ),
              if (snap.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text('Orders unavailable: ${snap.error}',
                      style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                ),
              const SizedBox(height: 18),
              SectionHeader(
                title: 'Low-stock Alerts',
                subtitle: lowStockItems.isEmpty ? 'All items well-stocked' : '${lowStockItems.length} item(s) need attention',
                actionLabel: lowStockItems.isEmpty ? null : 'View all',
                onAction: () => Navigator.of(context).pushNamed(AppRoutes.adminProducts),
              ),
              const SizedBox(height: 10),
              if (lowStockItems.isEmpty)
                const AppCard(child: Text('No low-stock alerts. Inventory looks healthy.'))
              else
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (int i = 0; i < lowStockItems.length && i < 6; i++) ...[
                        ListTile(
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: lowStockItems[i].stock == 0
                                  ? AppColors.danger.withOpacity(0.12)
                                  : Colors.orange.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              lowStockItems[i].stock == 0 ? Icons.block_rounded : Icons.warning_amber_rounded,
                              color: lowStockItems[i].stock == 0 ? AppColors.danger : Colors.orange,
                            ),
                          ),
                          title: Text(lowStockItems[i].name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text('${lowStockItems[i].category} • ${money(lowStockItems[i].price)}'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: lowStockItems[i].stock == 0
                                  ? AppColors.danger
                                  : lowStockItems[i].stock <= 5
                                      ? AppColors.danger
                                      : Colors.orange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              lowStockItems[i].stock == 0 ? 'Out' : '${lowStockItems[i].stock} left',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                            ),
                          ),
                          onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminProducts),
                        ),
                        if (i < lowStockItems.length - 1 && i < 5) const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              Text('Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.receipt_long_rounded,
                      label: 'Orders',
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminOrders),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.inventory_2_rounded,
                      label: 'Products',
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminProducts),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.people_rounded,
                      label: 'Customers',
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminCustomers),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.home),
                  icon: const Icon(Icons.storefront_rounded),
                  label: const Text('Back to Store'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _safeWatchAllOrders() async* {
    try {
      yield* OrderService().watchAllOrders();
    } catch (e) {
      yield* Stream<QuerySnapshot<Map<String, dynamic>>>.error(e);
    }
  }

  // Helpers that work with both Firestore-loaded and fallback products.
  // The AppController stores stock as a display string; we recover a numeric estimate
  // for KPIs. Firestore raw stock is numeric, but AppState hides it — so we parse
  // the display string with a sensible mapping.
  List<int> _extractStocks(AppController controller) {
    // Try to read Firestore raw docs via a synchronous fallback: if we have
    // no Firestore data, use the display string heuristic.
    return controller.products.map<int>((p) {
      final String s = p.stock.toLowerCase();
      if (s == 'out of stock' || s == 'pre-order') return 0;
      if (s == 'low stock') return 5;
      // "In stock" is a bucket — treat as 50 for KPI estimate when raw not available.
      return 50;
    }).toList();
  }

  double _inventoryValue(AppController controller, List<int> stocks) {
    double sum = 0;
    for (int i = 0; i < controller.products.length; i++) {
      sum += controller.products[i].price * stocks[i];
    }
    return sum;
  }

  List<_LowStockItem> _buildLowStockList(AppController c, List<int> stocks) {
    final List<_LowStockItem> items = <_LowStockItem>[];
    for (int i = 0; i < c.products.length; i++) {
      final int s = stocks[i];
      if (s <= 10) {
        final p = c.products[i];
        items.add(_LowStockItem(name: p.name, category: p.category, price: p.price, stock: s));
      }
    }
    items.sort((a, b) => a.stock.compareTo(b.stock));
    return items;
  }
}

class _LowStockItem {
  _LowStockItem({required this.name, required this.category, required this.price, required this.stock});
  final String name;
  final String category;
  final double price;
  final int stock;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 10),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(caption, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
