import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../services/admin_service.dart';
import '../../services/order_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final OrderService _orderService = OrderService();
  final AdminService _adminService = AdminService();

  String? _role;
  bool _checkingRole = true;
  String _filter = 'all';
  final Set<String> _updatingIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadRole();
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

  @override
  Widget build(BuildContext context) {
    if (_checkingRole) {
      return const MobileScaffold(
        appBar: ScreenTitleBar(title: 'All Orders'),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_isAdmin) {
      return MobileScaffold(
        appBar: const ScreenTitleBar(title: 'All Orders'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_rounded, size: 48, color: AppColors.danger),
                const SizedBox(height: 12),
                const Text('Admin access required', style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
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
      appBar: const ScreenTitleBar(title: 'All Orders'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filter,
                    decoration: const InputDecoration(
                      labelText: 'Filter by status',
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All statuses')),
                      DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'Processing', child: Text('Processing')),
                      DropdownMenuItem(value: 'Shipped', child: Text('Shipped')),
                      DropdownMenuItem(value: 'Delivered', child: Text('Delivered')),
                      DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                    ],
                    onChanged: (v) => setState(() => _filter = v ?? 'all'),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.tonalIcon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _orderService.watchAllOrders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _OrdersMessage(
                    icon: Icons.error_outline_rounded,
                    title: 'Unable to load orders',
                    message: '${snapshot.error}',
                  );
                }
                final docs = snapshot.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                // Client-side filter
                final filtered = _filter == 'all'
                    ? docs
                    : docs.where((d) => (d.data()['status']?.toString().toLowerCase() ?? '') == _filter.toLowerCase()).toList();

                if (docs.isEmpty) {
                  return const _OrdersMessage(
                    icon: Icons.receipt_long_outlined,
                    title: 'No orders yet',
                    message: 'Orders placed via the app will appear here.',
                  );
                }
                if (filtered.isEmpty) {
                  return _OrdersMessage(
                    icon: Icons.filter_list_off_rounded,
                    title: 'No "$_filter" orders',
                    message: 'Try a different filter.',
                  );
                }

                // Show counts
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('${filtered.length} of ${docs.length} orders',
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final doc = filtered[index];
                          final data = doc.data();
                          return _AdminOrderCard(
                            orderId: doc.id,
                            data: data,
                            isUpdating: _updatingIds.contains(doc.id),
                            onStatusChanged: (newStatus) => _updateStatus(doc.id, newStatus),
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                AppRoutes.orderDetails,
                                arguments: <String, dynamic>{
                                  'orderId': doc.id,
                                  'orderData': data,
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    setState(() => _updatingIds.add(orderId));
    try {
      await _orderService.updateOrderStatus(orderId: orderId, status: newStatus);
      if (!mounted) return;
      showAppSnackBar(context, 'Order status updated to $newStatus');
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, 'Update failed: $e');
    } finally {
      if (mounted) setState(() => _updatingIds.remove(orderId));
    }
  }
}

class _AdminOrderCard extends StatelessWidget {
  const _AdminOrderCard({
    required this.orderId,
    required this.data,
    required this.isUpdating,
    required this.onStatusChanged,
    required this.onTap,
  });

  final String orderId;
  final Map<String, dynamic> data;
  final bool isUpdating;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String orderNumber = _readText(data, 'orderNumber', fallback: '#${orderId.substring(0, 8).toUpperCase()}');
    final String status = _readText(data, 'status', fallback: 'Pending');
    final double total = _readDouble(data['total']);
    final DateTime createdAt = _readDate(data['createdAt']);
    final List<Map<String, dynamic>> items = _readItems(data['items']);
    final int itemCount = _getItemCount(data, items);
    final Color statusColor = _statusColor(status);
    final String customer = (data['customerEmail'] ?? data['customer'] ?? '').toString().trim().isNotEmpty
        ? (data['customerEmail'] ?? data['customer']).toString()
        : 'Customer';

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(orderNumber, style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(_formatDate(createdAt), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(customer, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
          const Divider(height: 18),
          Row(
            children: [
              Expanded(
                child: Text('$itemCount item${itemCount == 1 ? '' : 's'} • ${items.isEmpty ? '' : _itemSummary(items)}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
              ),
              const SizedBox(width: 8),
              Text(money(total),
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: isUpdating
                    ? const SizedBox(height: 36, child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))))
                    : DropdownButtonFormField<String>(
                        value: OrderService.orderStatuses.contains(status) ? status : 'Pending',
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        items: OrderService.orderStatuses
                            .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (v) {
                          if (v != null && v != status) onStatusChanged(v);
                        },
                      ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: onTap,
                child: const Text('Details'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- helpers duplicated for self-containment (keeps file import-free from orders_screen) ----
  static String _readText(Map<String, dynamic> d, String f, {String fallback = ''}) {
    final String t = d[f]?.toString().trim() ?? '';
    return t.isEmpty ? fallback : t;
  }

  static double _readDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  static DateTime _readDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static List<Map<String, dynamic>> _readItems(dynamic v) {
    if (v is! List) return <Map<String, dynamic>>[];
    return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static int _getItemCount(Map<String, dynamic> d, List<Map<String, dynamic>> items) {
    final dynamic saved = d['itemCount'];
    if (saved is num) return saved.toInt();
    return items.fold<int>(0, (t, e) => t + ((e['quantity'] as num?)?.toInt() ?? 1));
  }

  static String _formatDate(DateTime d) {
    if (d.millisecondsSinceEpoch == 0) return 'Date unavailable';
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  static Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'delivered':
        return AppColors.success;
      case 'shipped':
        return Colors.blue;
      case 'cancelled':
      case 'canceled':
        return AppColors.danger;
      case 'processing':
        return Colors.deepOrange;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  static String _itemSummary(List<Map<String, dynamic>> items) {
    return items.take(2).map((e) => '${e['quantity'] ?? 1}× ${e['name'] ?? 'Product'}').join(', ');
  }
}

class _OrdersMessage extends StatelessWidget {
  const _OrdersMessage({required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
