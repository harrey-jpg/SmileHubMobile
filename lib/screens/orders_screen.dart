import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/order_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

import '../routes.dart';


class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() =>
      _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderService _orderService = OrderService();

  late final Stream<
      QuerySnapshot<Map<String, dynamic>>> _ordersStream;

  @override
  void initState() {
    super.initState();

    _ordersStream = _orderService.watchMyOrders();
  }

  @override
  Widget build(BuildContext context) {
    return MobileScaffold(
      appBar: const ScreenTitleBar(
        title: 'My Orders',
        showBack: false,
      ),
      bottomNavigationBar:
          const MainBottomNavigation(
        currentIndex: 3,
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: _ordersStream,
        builder: (
          BuildContext context,
          AsyncSnapshot<
              QuerySnapshot<Map<String, dynamic>>>
              snapshot,
        ) {
          if (snapshot.connectionState ==
                  ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            debugPrint(
              'LOAD ORDERS ERROR: ${snapshot.error}',
            );

            return _OrdersMessage(
              icon: Icons.error_outline_rounded,
              title: 'Unable to load orders',
              message:
                  'Check your internet connection and try again.',
            );
          }

          final List<
                  QueryDocumentSnapshot<
                      Map<String, dynamic>>>
              documents =
              List<
                  QueryDocumentSnapshot<
                      Map<String, dynamic>>>.from(
            snapshot.data?.docs ??
                <QueryDocumentSnapshot<
                    Map<String, dynamic>>>[],
          );

          documents.sort(
            (
              QueryDocumentSnapshot<
                      Map<String, dynamic>>
                  first,
              QueryDocumentSnapshot<
                      Map<String, dynamic>>
                  second,
            ) {
              final DateTime firstDate =
                  _readDate(first.data()['createdAt']);

              final DateTime secondDate =
                  _readDate(second.data()['createdAt']);

              return secondDate.compareTo(firstDate);
            },
          );

          if (documents.isEmpty) {
            return const _OrdersMessage(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              message:
                  'Your completed orders will appear here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              28,
            ),
            itemCount: documents.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: 12),
            itemBuilder: (
              BuildContext context,
              int index,
            ) {
              final Map<String, dynamic> data =
                  documents[index].data();

              return _OrderCard(
                orderId: documents[index].id,
                data: data,
              );
            },
          );
        },
      ),
    );
  }

  static DateTime _readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.orderId,
    required this.data,
  });

  final String orderId;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final String orderNumber =
        _readText(
          data,
          'orderNumber',
          fallback:
              '#${orderId.substring(0, 8).toUpperCase()}',
        );

    final String status =
        _readText(
          data,
          'status',
          fallback: 'Pending',
        );

    final double total =
        _readDouble(data['total']);

    final DateTime createdAt =
        _readDate(data['createdAt']);

    final List<Map<String, dynamic>> items =
        _readItems(data['items']);

    final int itemCount =
        _getItemCount(data, items);

    final Color statusColor =
        _getStatusColor(status);

    final List<Map<String, dynamic>> visibleItems =
        items.take(2).toList();

return AppCard(
  onTap: () {
    Navigator.of(context).pushNamed(
      AppRoutes.orderDetails,
      arguments: <String, dynamic>{
        'orderId': orderId,
        'orderData': data,
      },
    );
  },
  child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  orderNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(31),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          Text(
            _formatDate(createdAt),
            style:
                Theme.of(context).textTheme.bodySmall,
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              ...visibleItems.map(
                (Map<String, dynamic> item) {
                  return Padding(
                    padding:
                        const EdgeInsets.only(
                      right: 8,
                    ),
                    child: _OrderProductIcon(
                      icon: _iconForItem(item),
                    ),
                  );
                },
              ),

              if (visibleItems.isEmpty)
                const _OrderProductIcon(
                  icon:
                      Icons.shopping_bag_outlined,
                ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  '$itemCount '
                  '${itemCount == 1 ? 'item' : 'items'}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall,
                ),
              ),

              Text(
                money(total),
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          if (items.isNotEmpty) ...[
            const Divider(height: 24),

            Text(
              _itemSummary(items),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _readText(
    Map<String, dynamic> data,
    String field, {
    String fallback = '',
  }) {
    final String text =
        data[field]?.toString().trim() ?? '';

    return text.isEmpty ? fallback : text;
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static DateTime _readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static List<Map<String, dynamic>> _readItems(
    dynamic value,
  ) {
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map(
          (Map item) =>
              Map<String, dynamic>.from(item),
        )
        .toList();
  }

  static int _getItemCount(
    Map<String, dynamic> data,
    List<Map<String, dynamic>> items,
  ) {
    final dynamic savedCount = data['itemCount'];

    if (savedCount is num) {
      return savedCount.toInt();
    }

    return items.fold<int>(
      0,
      (
        int total,
        Map<String, dynamic> item,
      ) {
        final dynamic quantity = item['quantity'];

        return total +
            (quantity is num
                ? quantity.toInt()
                : 1);
      },
    );
  }

  static String _formatDate(DateTime date) {
    if (date.millisecondsSinceEpoch == 0) {
      return 'Processing date...';
    }

    const List<String> months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} '
        '${date.day}, ${date.year}';
  }

  static Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
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

  static IconData _iconForItem(
    Map<String, dynamic> item,
  ) {
    final String category =
        item['category']
                ?.toString()
                .toLowerCase() ??
            '';

    if (category.contains('equipment')) {
      return Icons.medical_services_outlined;
    }

    if (category.contains('instrument')) {
      return Icons.build_outlined;
    }

    if (category.contains('ppe')) {
      return Icons.masks_outlined;
    }

    if (category.contains('oral')) {
      return Icons.cleaning_services_outlined;
    }

    if (category.contains('impression')) {
      return Icons.science_outlined;
    }

    return Icons.shopping_bag_outlined;
  }

  static String _itemSummary(
    List<Map<String, dynamic>> items,
  ) {
    return items.map(
      (Map<String, dynamic> item) {
        final String name =
            item['name']?.toString() ??
                'Product';

        final int quantity =
            item['quantity'] is num
                ? (item['quantity'] as num)
                    .toInt()
                : 1;

        return '$quantity× $name';
      },
    ).join(', ');
  }
}

class _OrderProductIcon extends StatelessWidget {
  const _OrderProductIcon({
    required this.icon,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color:
            Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _OrdersMessage extends StatelessWidget {
  const _OrdersMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 58,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),

            const SizedBox(height: 16),

            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),

            const SizedBox(height: 8),

            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}