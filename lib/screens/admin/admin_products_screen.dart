import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final AdminService _adminService = AdminService();

  String? _role;
  bool _checkingRole = true;
  String _query = '';
  String _category = 'All';
  final Map<String, TextEditingController> _stockControllers = <String, TextEditingController>{};
  final Set<String> _updating = <String>{};

  static const List<String> _categories = <String>[
    'All',
    'Oral Care',
    'Instruments',
    'PPE',
    'Restorative',
    'Disposables',
    'Impression',
    'Orthodontics',
    'Rotary',
    'Equipment',
    'Cosmetic',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  @override
  void dispose() {
    for (final c in _stockControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadRole() async {
    final String? r = await _adminService.getCurrentUserRole();
    if (!mounted) return;
    setState(() {
      _role = r;
      _checkingRole = false;
    });
  }

  bool get _isAdmin {
    final String r = (_role ?? '').toLowerCase();
    return AdminService.adminRoles.contains(r);
  }

  TextEditingController _controllerFor(String docId, int currentStock) {
    return _stockControllers.putIfAbsent(docId, () => TextEditingController(text: '$currentStock'));
  }

  Future<void> _updateStock(String docId, int productId) async {
    final TextEditingController? ctrl = _stockControllers[docId];
    if (ctrl == null) return;
    final String raw = ctrl.text.trim();
    final int? val = int.tryParse(raw);
    if (val == null || val < 0) {
      showAppSnackBar(context, 'Enter a valid stock (0 or more).');
      return;
    }
    setState(() => _updating.add(docId));
    try {
      await _adminService.updateProductStock(productId: productId, newStock: val);
      // Refresh catalog so AppController / customer views see the new stock.
      if (mounted) {
        final AppController app = AppScope.read(context);
        await app.loadProductsFromFirestore();
      }
      if (!mounted) return;
      showAppSnackBar(context, 'Stock updated to $val.');
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, 'Update failed: $e');
    } finally {
      if (mounted) setState(() => _updating.remove(docId));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingRole) {
      return const MobileScaffold(
        appBar: ScreenTitleBar(title: 'Products / Inventory'),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_isAdmin) {
      return MobileScaffold(
        appBar: const ScreenTitleBar(title: 'Products / Inventory'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_rounded, size: 48, color: AppColors.danger),
                const SizedBox(height: 12),
                const Text('Admin access required', style: TextStyle(fontWeight: FontWeight.w900)),
                Text('Role: ${_role ?? 'unknown'}', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Go back')),
              ],
            ),
          ),
        ),
      );
    }

    return MobileScaffold(
      appBar: ScreenTitleBar(
        title: 'Products / Inventory',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _adminService.watchProductsRaw(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Unable to load products: ${snapshot.error}', textAlign: TextAlign.center),
              ),
            );
          }

          final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = snapshot.data?.docs ?? [];

          // Build display list; if Firestore is empty, fallback to AppController products
          List<Map<String, dynamic>> display;
          if (docs.isEmpty) {
            final AppController app = AppScope.of(context);
            display = app.products.map((p) => <String, dynamic>{
                  'docId': p.id.toString(),
                  'id': p.id,
                  'name': p.name,
                  'sku': '—',
                  'brand': p.brand,
                  'category': p.category,
                  'price': p.price,
                  'stock': p.stock.toLowerCase() == 'out of stock' ? 0 : p.stock.toLowerCase() == 'low stock' ? 5 : 50,
                  'status': p.stock,
                }).toList();
          } else {
            display = docs.map((d) {
              final Map<String, dynamic> data = d.data();
              final int stock = (data['stock'] as num?)?.toInt() ?? 0;
              final String status = (data['status'] ?? (stock == 0 ? 'Out of Stock' : stock <= 10 ? 'Low Stock' : 'Active')).toString();
              return <String, dynamic>{
                'docId': d.id,
                'id': (data['id'] as num?)?.toInt() ?? int.tryParse(d.id) ?? 0,
                'name': (data['name'] ?? 'Unnamed product').toString(),
                'sku': (data['sku'] ?? 'SH-${d.id}').toString(),
                'brand': (data['brand'] ?? '').toString(),
                'category': (data['category'] ?? 'General').toString(),
                'price': ((data['price'] as num?) ?? 0).toDouble(),
                'stock': stock,
                'status': status,
                '_raw': data,
              };
            }).toList();
          }

          // Filter by category + search
          final String normalized = _query.trim().toLowerCase();
          final List<Map<String, dynamic>> filtered = display.where((p) {
            final bool catOk = _category == 'All' || p['category'] == _category;
            if (!catOk) return false;
            if (normalized.isEmpty) return true;
            return p['name'].toString().toLowerCase().contains(normalized) ||
                p['sku'].toString().toLowerCase().contains(normalized) ||
                p['category'].toString().toLowerCase().contains(normalized) ||
                p['brand'].toString().toLowerCase().contains(normalized);
          }).toList();

          final int low = display.where((p) => (p['stock'] as int) > 0 && (p['stock'] as int) <= 10).length;
          final int out = display.where((p) => (p['stock'] as int) == 0).length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (v) => setState(() => _query = v),
                            decoration: const InputDecoration(
                              hintText: 'Search name, SKU, brand…',
                              prefixIcon: Icon(Icons.search_rounded),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final String cat = _categories[index];
                          return ChoiceChip(
                            label: Text(cat),
                            selected: _category == cat,
                            onSelected: (_) => setState(() => _category = cat),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text('${filtered.length} of ${display.length} products',
                              style: Theme.of(context).textTheme.bodySmall),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: out > 0 ? AppColors.danger.withOpacity(0.12) : AppColors.success.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('$low low • $out out',
                              style: TextStyle(
                                  color: out > 0 ? AppColors.danger : AppColors.success,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No products found.'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final Map<String, dynamic> p = filtered[index];
                          final String docId = p['docId'].toString();
                          final int prodId = (p['id'] as int?) ?? 0;
                          final int stock = (p['stock'] as int?) ?? 0;
                          final String status = p['status'].toString();
                          final Color statusColor = status.toLowerCase().contains('out')
                              ? AppColors.danger
                              : status.toLowerCase().contains('low')
                                  ? Colors.orange
                                  : AppColors.success;
                          final bool busy = _updating.contains(docId);
                          final TextEditingController ctrl = _controllerFor(docId, stock);
                          // Keep controller in sync if external update changed stock and field not focused
                          if (!busy && ctrl.text != '$stock' && !_isFieldFocused(ctrl)) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) ctrl.text = '$stock';
                            });
                          }

                          return AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(_iconForCategory(p['category'].toString()),
                                          color: Theme.of(context).colorScheme.primary),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p['name'].toString(),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontWeight: FontWeight.w800)),
                                          const SizedBox(height: 2),
                                          Text('${p['brand']} • ${p['sku']}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context).textTheme.bodySmall),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(money((p['price'] as num).toDouble()),
                                                  style: TextStyle(
                                                      color: Theme.of(context).colorScheme.primary,
                                                      fontWeight: FontWeight.w900,
                                                      fontSize: 13)),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: statusColor.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(status,
                                                    style: TextStyle(
                                                        color: statusColor,
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w800)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 18),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: ctrl,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Stock',
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        ),
                                        enabled: !busy,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      height: 44,
                                      child: FilledButton(
                                        onPressed: busy ? null : () => _updateStock(docId, prodId),
                                        child: busy
                                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                            : const Text('Update'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _isFieldFocused(TextEditingController ctrl) {
    // Cheap heuristic: if the text selection is not collapsed at 0, user is editing.
    // Full FocusNode tracking is unnecessary for this admin tool.
    return false;
  }

  static IconData _iconForCategory(String category) {
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
}
