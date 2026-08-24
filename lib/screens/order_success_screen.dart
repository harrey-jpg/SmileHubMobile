import 'package:flutter/material.dart';

import '../routes.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);

    final Object? rawArguments =
        ModalRoute.of(context)?.settings.arguments;

    final Map<String, dynamic> arguments =
        rawArguments is Map
            ? Map<String, dynamic>.from(rawArguments)
            : <String, dynamic>{};

    final String orderNumber =
        arguments['orderNumber']?.toString().trim() ?? '';

    final String paymentMethod =
        arguments['paymentMethod']?.toString().trim() ?? '';

    final String deliveryMethod =
        arguments['deliveryMethod']?.toString().trim() ?? '';

    final double total =
        arguments['total'] is num
            ? (arguments['total'] as num).toDouble()
            : 0;

    return MobileScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            22,
            40,
            22,
            30,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 54,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Order placed!',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),

              const SizedBox(height: 10),

              Text(
                'Thank you for shopping with SmileHub. '
                'We will notify you when your order ships.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 28),

              AppCard(
                child: Column(
                  children: [
                    _SuccessRow(
                      label: 'Order number',
                      value: orderNumber.isEmpty
                          ? 'Processing...'
                          : '#$orderNumber',
                    ),

                    _SuccessRow(
                      label: 'Payment',
                      value: paymentMethod.isEmpty
                          ? controller
                              .selectedPayment
                              .title
                          : paymentMethod,
                    ),

                    _SuccessRow(
                      label: 'Delivery',
                      value: deliveryMethod.isEmpty
                          ? 'Standard Delivery'
                          : deliveryMethod,
                    ),

                    const Divider(height: 24),

                    _SuccessRow(
                      label: 'Total',
                      value: money(total),
                      emphasized: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              ElevatedButton(
                onPressed: () {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(
                    AppRoutes.orders,
                    (_) => false,
                  );
                },
                child: const Text(
                  'View My Orders',
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: () {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(
                    AppRoutes.home,
                    (_) => false,
                  );
                },
                child: const Text(
                  'Continue Shopping',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessRow extends StatelessWidget {
  const _SuccessRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: emphasized
                    ? FontWeight.w900
                    : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}