import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/address_service.dart';
import '../state/app_state.dart';
import '../widgets/app_widgets.dart';
import '../services/order_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    this.buyNowProductId,
    this.buyNowQuantity = 1,
  });

  final int? buyNowProductId;
  final int buyNowQuantity;

  @override
  State<CheckoutScreen> createState() =>
      _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final AddressService _addressService = AddressService();
  
  final OrderService _orderService = OrderService();

  bool _isPlacingOrder = false;

  String _delivery = 'Standard Delivery';

  Map<String, dynamic>? _selectedAddress;
  bool _isLoadingAddress = true;

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
  }

  Future<void> _loadDefaultAddress() async {
    try {
      final Map<String, dynamic>? address =
          await _addressService.getDefaultAddress();

      if (!mounted) return;

      setState(() {
        _selectedAddress = address;
        _isLoadingAddress = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingAddress = false;
      });

      debugPrint('LOAD CHECKOUT ADDRESS ERROR: $error');
    }
  }

  Future<void> _changeAddress() async {
    final Object? result =
        await Navigator.of(context).pushNamed(
      AppRoutes.addresses,
      arguments: true,
    );

    if (!mounted) return;

    if (result is Map<String, dynamic>) {
      setState(() {
        _selectedAddress = result;
      });
    } else if (result is Map) {
      setState(() {
        _selectedAddress =
            Map<String, dynamic>.from(result);
      });
    }
  }

  String _readAddressField(String field) {
    return _selectedAddress?[field]
            ?.toString()
            .trim() ??
        '';
  }

  String get _fullAddress {
    final String savedAddress =
        _readAddressField('fullAddress');

    if (savedAddress.isNotEmpty) {
      return savedAddress;
    }

    return <String>[
      _readAddressField('street'),
      _readAddressField('barangay'),
      _readAddressField('city'),
      _readAddressField('postalCode'),
    ].where((value) => value.isNotEmpty).join(', ');
  }
  Map<int, int> _checkoutItems(
    AppController controller,
  ) {
    if (widget.buyNowProductId != null) {
      return <int, int>{
        widget.buyNowProductId!: widget.buyNowQuantity,
      };
    }

    return controller.cart;
  }

  double _checkoutSubtotal(
    AppController controller,
  ) {
    final Map<int, int> items = _checkoutItems(controller);

    return items.entries.fold<double>(
      0,
      (double total, MapEntry<int, int> entry) {
        final product = controller.productById(entry.key);
        return total + (product.price * entry.value);
      },
    );
  }

  double _checkoutShippingFee(
    AppController controller,
  ) {
    final double subtotal = _checkoutSubtotal(controller);

    if (subtotal == 0 || subtotal >= 3000) {
      return 0;
    }

    return 120;
  }

  double _checkoutDiscount(
    AppController controller,
  ) {
    if (!controller.couponApplied) {
      return 0;
    }

    return (_checkoutSubtotal(controller) * 0.10)
        .clamp(0, 349.90)
        .toDouble();
  }

  Future<void> _placeOrder(
    AppController controller,
  ) async {
    if (_selectedAddress == null) {
      showAppSnackBar(
        context,
        'Select a shipping address first.',
      );
      return;
    }

    final Map<int, int> checkoutItems =
        _checkoutItems(controller);

    if (checkoutItems.isEmpty) {
      showAppSnackBar(
        context,
        'Your cart is empty.',
      );
      return;
    }

    setState(() {
      _isPlacingOrder = true;
    });

    try {
      final double subtotal =
          _checkoutSubtotal(controller);

      final double standardShippingFee =
          _checkoutShippingFee(controller);

      final double shippingFee =
          _delivery == 'Express Delivery'
              ? 220
              : standardShippingFee;

      final double discount =
          _checkoutDiscount(controller);

      final double total =
          subtotal + shippingFee - discount;

      final List<Map<String, dynamic>> items =
          checkoutItems.entries.map((entry) {
        final product =
            controller.productById(entry.key);

        return <String, dynamic>{
          'productId': product.id,
          'name': product.name,
          'brand': product.brand,
          'category': product.category,
          'price': product.price,
          'quantity': entry.value,
          'lineTotal': product.price * entry.value,
        };
      }).toList();

      final Map<String, dynamic> address =
          _selectedAddress!;

      final Map<String, String> result =
          await _orderService.placeOrder(
        items: items,
        shippingAddress: {
          'addressId':
              address['addressId']?.toString() ?? '',
          'label': address['label']?.toString() ?? '',
          'recipient':
              address['recipient']?.toString() ?? '',
          'phone': address['phone']?.toString() ?? '',
          'street': address['street']?.toString() ?? '',
          'barangay':
              address['barangay']?.toString() ?? '',
          'city': address['city']?.toString() ?? '',
          'postalCode':
              address['postalCode']?.toString() ?? '',
          'fullAddress':
              address['fullAddress']?.toString() ?? '',
        },
        deliveryMethod: _delivery,
        paymentMethod:
            controller.selectedPayment.title,
        subtotal: subtotal,
        shippingFee: shippingFee,
        discount: discount,
        total: total,
      );

      if (!mounted) return;

      // Regular cart checkout lang ang i-clear.
      // Sa Buy Now, hindi gagalawin ang existing cart.
      if (widget.buyNowProductId == null) {
        controller.clearCartAfterOrder();
      }

      showAppSnackBar(
        context,
        'Order ${result['orderNumber']} placed.',
      );

Navigator.of(context).pushReplacementNamed(
  AppRoutes.orderSuccess,
  arguments: <String, dynamic>{
    ...result,
    'paymentMethod': controller.selectedPayment.title,
    'deliveryMethod': _delivery,
    'total': total,
  },
);
    } catch (error) {
      if (!mounted) return;

      showAppSnackBar(
        context,
        'Unable to place order.',
      );

      debugPrint('PLACE ORDER ERROR: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);

    final double checkoutSubtotal =
        _checkoutSubtotal(controller);

    final double checkoutDiscount =
        _checkoutDiscount(controller);

    final double standardShippingFee =
        _checkoutShippingFee(controller);

    final double selectedShippingFee =
        _delivery == 'Express Delivery'
            ? 220
            : standardShippingFee;

    final double orderTotal =
        checkoutSubtotal +
        selectedShippingFee -
        checkoutDiscount;

    return MobileScaffold(
      appBar: const ScreenTitleBar(
        title: 'Checkout',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          30,
        ),
        children: [
          const Row(
            children: [
              Expanded(
                child: _StepChip(
                  number: 1,
                  label: 'Shipping',
                  active: true,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _StepChip(
                  number: 2,
                  label: 'Payment',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _StepChip(
                  number: 3,
                  label: 'Review',
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          SectionHeader(
            title: 'Shipping Address',
            actionLabel: _selectedAddress == null
                ? 'Add'
                : 'Change',
            onAction: _changeAddress,
          ),

          const SizedBox(height: 10),

          if (_isLoadingAddress)
            const AppCard(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (_selectedAddress == null)
            AppCard(
              onTap: _changeAddress,
              child: const Row(
                children: [
                  Icon(Icons.add_location_alt_outlined),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No shipping address selected. '
                      'Tap to add or choose an address.',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded),
                ],
              ),
            )
          else
            AppCard(
              onTap: _changeAddress,
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
                        _readAddressField('label').isEmpty
                            ? 'Address'
                            : _readAddressField('label'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right_rounded,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Text(
                    _readAddressField('recipient'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(_readAddressField('phone')),

                  const SizedBox(height: 4),

                  Text(
                    _fullAddress,
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

          const SizedBox(height: 22),

          const SectionHeader(
            title: 'Delivery Method',
          ),

          const SizedBox(height: 10),

          _DeliveryOption(
            title: 'Standard Delivery',
            subtitle: '3–5 business days',
            fee: standardShippingFee == 0
                ? 'Free'
                : money(standardShippingFee),
            selected:
                _delivery == 'Standard Delivery',
            onTap: () {
              setState(() {
                _delivery = 'Standard Delivery';
              });
            },
          ),

          const SizedBox(height: 10),

          _DeliveryOption(
            title: 'Express Delivery',
            subtitle: '1–2 business days',
            fee: '₱220',
            selected:
                _delivery == 'Express Delivery',
            onTap: () {
              setState(() {
                _delivery = 'Express Delivery';
              });
            },
          ),

          const SizedBox(height: 22),

          SectionHeader(
            title: 'Payment Method',
            actionLabel: 'Change',
            onAction: () {
              Navigator.of(context).pushNamed(
                AppRoutes.payments,
                arguments: true,
              );
            },
          ),

          const SizedBox(height: 10),

          AppCard(
            onTap: () {
              Navigator.of(context).pushNamed(
                AppRoutes.payments,
                arguments: true,
              );
            },
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                  child: Icon(
                    controller.selectedPayment.icon,
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
                        controller.selectedPayment.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        controller
                            .selectedPayment.subtitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall,
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.chevron_right_rounded,
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          AppCard(
            child: Column(
              children: [
                _OrderRow(
                  label: 'Subtotal',
                  value: money(checkoutSubtotal),
                ),

                _OrderRow(
                  label: 'Shipping',
                  value: selectedShippingFee == 0
                      ? 'Free'
                      : money(selectedShippingFee),
                ),

                if (checkoutDiscount > 0)
                  _OrderRow(
                    label: 'Discount',
                    value:
                        '−${money(checkoutDiscount)}',
                  ),

                const Divider(height: 24),

                _OrderRow(
                  label: 'Order Total',
                  value: money(orderTotal),
                  emphasized: true,
                ),

                if (controller.couponApplied) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Coupon SMILE10 applied',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 18),

                ElevatedButton(
                  onPressed:
                      _isLoadingAddress || _isPlacingOrder
                          ? null
                          : () => _placeOrder(controller),
                  child: Text(
                    _isPlacingOrder
                        ? 'Placing order...'
                        : 'Place Order',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({
    required this.number,
    required this.label,
    this.active = false,
  });

  final int number;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: active
            ? Theme.of(context)
                .colorScheme
                .primaryContainer
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 10,
            child: Text(
              '$number',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryOption extends StatelessWidget {
  const _DeliveryOption({
    required this.title,
    required this.subtitle,
    required this.fee,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String fee;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Radio<bool>(
            value: true,
            groupValue: selected,
            onChanged: (_) => onTap(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style:
                      Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            fee,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = emphasized
        ? Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(
              fontWeight: FontWeight.w900,
            )
        : Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: style),
          ),
          Text(
            value,
            style: style?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}