import 'package:flutter/material.dart';

import '../routes.dart';
import '../state/app_state.dart';
import '../widgets/app_widgets.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key, this.selectionMode = false});

  final bool selectionMode;

  @override
  Widget build(BuildContext context) {
    final AppController controller = AppScope.of(context);

    return MobileScaffold(
      appBar: const ScreenTitleBar(title: 'Payment Methods'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text('Choose your preferred payment method.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 14),
          ...List.generate(controller.paymentMethods.length, (index) {
            final method = controller.paymentMethods[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                onTap: () {
                  controller.selectPayment(index);
                  if (selectionMode) Navigator.of(context).pop();
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(method.icon, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(method.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 3),
                          Text(method.subtitle, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    if (method.isDefault) const Chip(label: Text('Default')),
                    Radio<int>(
                      value: index,
                      groupValue: controller.selectedPaymentIndex,
                      onChanged: (value) {
                        controller.selectPayment(value ?? index);
                        if (selectionMode) Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.addPayment),
            icon: const Icon(Icons.add_card_rounded),
            label: const Text('Add Payment Method'),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_rounded, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                const Expanded(child: Text('Your payment details are encrypted and are not shared with sellers.')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
