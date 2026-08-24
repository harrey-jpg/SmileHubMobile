import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({
    super.key,
    required this.orderId,
    required this.orderData,
  });

  final String orderId;
  final Map<String, dynamic> orderData;

  @override
  Widget build(BuildContext context) {
    return MobileScaffold(
      appBar: const ScreenTitleBar(
        title: 'Order Details',
      ),
      body: StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .snapshots(),
        builder: (
          BuildContext context,
          AsyncSnapshot<
              DocumentSnapshot<Map<String, dynamic>>>
              snapshot,
        ) {
          Map<String, dynamic> data = orderData;

          if (snapshot.hasData &&
              snapshot.data!.exists &&
              snapshot.data!.data() != null) {
            data = snapshot.data!.data()!;
          }

          if (snapshot.hasError) {
            debugPrint(
              'ORDER DETAILS ERROR: ${snapshot.error}',
            );
          }

          return _OrderDetailsContent(
            orderId: orderId,
            data: data,
          );
        },
      ),
    );
  }
}

class _OrderDetailsContent extends StatelessWidget {
  const _OrderDetailsContent({
    required this.orderId,
    required this.data,
  });

  final String orderId;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final String savedOrderNumber =
        data['orderNumber']?.toString().trim() ?? '';

    final String orderNumber =
        savedOrderNumber.isNotEmpty
            ? (savedOrderNumber.startsWith('#')
                ? savedOrderNumber
                : '#$savedOrderNumber')
            : '#${orderId.substring(
                0,
                orderId.length >= 8 ? 8 : orderId.length,
              ).toUpperCase()}';

    final String status =
        data['status']?.toString().trim().isNotEmpty == true
            ? data['status'].toString()
            : 'Pending';

    final DateTime createdAt =
        _readDate(data['createdAt']);

    final List<Map<String, dynamic>> items =
        _readItems(data['items']);

    final Map<String, dynamic> address =
        _readMap(data['shippingAddress']);

    final double subtotal =
        _readDouble(data['subtotal']);

    final double shippingFee =
        _readDouble(data['shippingFee']);

    final double discount =
        _readDouble(data['discount']);

    final double total =
        _readDouble(data['total']);

    final String deliveryMethod =
        data['deliveryMethod']?.toString() ??
            'Standard Delivery';

    final String paymentMethod =
        data['paymentMethod']?.toString() ??
            'Cash on Delivery';

    final Color statusColor =
        _statusColor(status);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        28,
      ),
      children: [
        AppCard(
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
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(30),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                'Placed on ${_formatDate(createdAt)}',
                style:
                    Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        const Text(
          'Order Status',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 10),

        AppCard(
          child: _OrderStatusTracker(
            status: status,
          ),
        ),

        const SizedBox(height: 18),

        const Text(
          'Items',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 10),

        AppCard(
          child: items.isEmpty
              ? const Text(
                  'No product information available.',
                )
              : Column(
                  children: [
                    for (int index = 0;
                        index < items.length;
                        index++) ...[
                      _OrderItemRow(
                        item: items[index],
                      ),
                      if (index < items.length - 1)
                        const Divider(
                          height: 24,
                        ),
                    ],
                  ],
                ),
        ),

        const SizedBox(height: 18),

        const Text(
          'Shipping Address',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 10),

        AppCard(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    address['label']
                                ?.toString()
                                .trim()
                                .isNotEmpty ==
                            true
                        ? address['label'].toString()
                        : 'Address',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                address['recipient']?.toString() ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                address['phone']?.toString() ?? '',
              ),

              const SizedBox(height: 4),

              Text(
                _fullAddress(address),
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        const Text(
          'Delivery & Payment',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 10),

        AppCard(
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.local_shipping_outlined,
                label: 'Delivery Method',
                value: deliveryMethod,
              ),

              const Divider(height: 24),

              _InfoRow(
                icon: Icons.payments_outlined,
                label: 'Payment Method',
                value: paymentMethod,
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        const Text(
          'Order Summary',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 10),

        AppCard(
          child: Column(
            children: [
              _PriceRow(
                label: 'Subtotal',
                value: money(subtotal),
              ),

              const SizedBox(height: 10),

              _PriceRow(
                label: 'Shipping',
                value: shippingFee == 0
                    ? 'Free'
                    : money(shippingFee),
              ),

              if (discount > 0) ...[
                const SizedBox(height: 10),
                _PriceRow(
                  label: 'Discount',
                  value: '-${money(discount)}',
                ),
              ],

              const Divider(height: 24),

              _PriceRow(
                label: 'Total',
                value: money(total),
                emphasized: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static DateTime _readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
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

  static List<Map<String, dynamic>> _readItems(
    dynamic value,
  ) {
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map(
          (item) =>
              Map<String, dynamic>.from(item),
        )
        .toList();
  }

  static Map<String, dynamic> _readMap(
    dynamic value,
  ) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  static String _fullAddress(
    Map<String, dynamic> address,
  ) {
    final String saved =
        address['fullAddress']
                ?.toString()
                .trim() ??
            '';

    if (saved.isNotEmpty) {
      return saved;
    }

    return <String>[
      address['street']?.toString() ?? '',
      address['barangay']?.toString() ?? '',
      address['city']?.toString() ?? '',
      address['postalCode']?.toString() ?? '',
    ].where(
      (value) => value.trim().isNotEmpty,
    ).join(', ');
  }

  static String _formatDate(DateTime date) {
    if (date.millisecondsSinceEpoch == 0) {
      return 'Date unavailable';
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

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return AppColors.success;

      case 'shipped':
        return Colors.blue;

      case 'processing':
        return Colors.deepOrange;

      case 'cancelled':
      case 'canceled':
        return AppColors.danger;

      case 'pending':
      default:
        return Colors.orange;
    }
  }
}

class _OrderStatusTracker extends StatelessWidget {
  const _OrderStatusTracker({
    required this.status,
  });

  final String status;

  int get _currentStep {
    switch (status.toLowerCase()) {
      case 'delivered':
        return 3;

      case 'shipped':
        return 2;

      case 'processing':
        return 1;

      case 'pending':
      default:
        return 0;
    }
  }

  bool get _isCancelled {
    final String value = status.toLowerCase();

    return value == 'cancelled' ||
        value == 'canceled';
  }

  @override
  Widget build(BuildContext context) {
    if (_isCancelled) {
      return Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.danger,
            child: Icon(
              Icons.close_rounded,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Cancelled',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'This order has been cancelled.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall,
                ),
              ],
            ),
          ),
        ],
      );
    }

    final List<_StatusStepData> steps =
        <_StatusStepData>[
      const _StatusStepData(
        title: 'Order Placed',
        subtitle: 'Your order has been received.',
        icon: Icons.receipt_long_rounded,
      ),
      const _StatusStepData(
        title: 'Processing',
        subtitle: 'Your order is being prepared.',
        icon: Icons.inventory_2_outlined,
      ),
      const _StatusStepData(
        title: 'Shipped',
        subtitle: 'Your order is on the way.',
        icon: Icons.local_shipping_outlined,
      ),
      const _StatusStepData(
        title: 'Delivered',
        subtitle: 'Your order has arrived.',
        icon: Icons.check_circle_outline_rounded,
      ),
    ];

    return Column(
      children: [
        for (int index = 0;
            index < steps.length;
            index++)
          _StatusStep(
            data: steps[index],
            completed: index <= _currentStep,
            active: index == _currentStep,
            showLine:
                index < steps.length - 1,
          ),
      ],
    );
  }
}

class _StatusStepData {
  const _StatusStepData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

class _StatusStep extends StatelessWidget {
  const _StatusStep({
    required this.data,
    required this.completed,
    required this.active,
    required this.showLine,
  });

  final _StatusStepData data;
  final bool completed;
  final bool active;
  final bool showLine;

  @override
  Widget build(BuildContext context) {
    final Color activeColor =
        Theme.of(context).colorScheme.primary;

    final Color inactiveColor =
        Theme.of(context).dividerColor;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 42,
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: completed
                        ? activeColor
                        : Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: completed
                          ? activeColor
                          : inactiveColor,
                    ),
                  ),
                  child: Icon(
                    completed
                        ? Icons.check_rounded
                        : data.icon,
                    size: 18,
                    color: completed
                        ? Colors.white
                        : Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                  ),
                ),

                if (showLine)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin:
                          const EdgeInsets.symmetric(
                        vertical: 4,
                      ),
                      color: completed &&
                              !active
                          ? activeColor
                          : inactiveColor,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: showLine ? 22 : 0,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: TextStyle(
                      fontWeight: active
                          ? FontWeight.w900
                          : FontWeight.w800,
                      color: completed
                          ? null
                          : Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    data.subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall,
                  ),

                  if (active) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Current status',
                      style: TextStyle(
                        color: activeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({
    required this.item,
  });

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final String name =
        item['name']?.toString() ?? 'Product';

    final String brand =
        item['brand']?.toString() ?? '';

    final int quantity =
        item['quantity'] is num
            ? (item['quantity'] as num).toInt()
            : 1;

    final double price =
        item['price'] is num
            ? (item['price'] as num).toDouble()
            : 0;

    final double lineTotal =
        item['lineTotal'] is num
            ? (item['lineTotal'] as num).toDouble()
            : price * quantity;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primaryContainer,
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.shopping_bag_outlined,
            color: Theme.of(context)
                .colorScheme
                .primary,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),

              if (brand.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  brand,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall,
                ),
              ],

              const SizedBox(height: 5),

              Text(
                '$quantity × ${money(price)}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall,
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        Text(
          money(lineTotal),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color:
              Theme.of(context).colorScheme.primary,
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall,
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = TextStyle(
      fontSize: emphasized ? 17 : 14,
      fontWeight: emphasized
          ? FontWeight.w900
          : FontWeight.w500,
    );

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: style,
          ),
        ),
        Text(
          value,
          style: style.copyWith(
            fontWeight: FontWeight.w900,
            color: emphasized
                ? Theme.of(context)
                    .colorScheme
                    .primary
                : null,
          ),
        ),
      ],
    );
  }
}