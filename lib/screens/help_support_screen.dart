import 'package:flutter/material.dart';

import '../routes.dart';
import '../widgets/app_widgets.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MobileScaffold(
      appBar: const ScreenTitleBar(title: 'Help & Support'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search help topics...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onSubmitted: (_) => showAppSnackBar(context, 'Help search is simulated.'),
          ),
          const SizedBox(height: 22),
          Text('How can we help?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.25,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _HelpTopic(icon: Icons.local_shipping_outlined, label: 'Order concern', onTap: () => _openContact(context, 'Order concern')),
              _HelpTopic(icon: Icons.payments_outlined, label: 'Payment concern', onTap: () => _openContact(context, 'Payment concern')),
              _HelpTopic(icon: Icons.manage_accounts_outlined, label: 'Account help', onTap: () => _openContact(context, 'Account help')),
              _HelpTopic(icon: Icons.inventory_2_outlined, label: 'Product question', onTap: () => _openContact(context, 'Product question')),
            ],
          ),
          const SizedBox(height: 24),
          Text('Frequently Asked Questions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: const [
                _FaqTile(title: 'How do I track my order?', answer: 'Open My Account and select your latest order to view its current status.'),
                Divider(height: 1),
                _FaqTile(title: 'Can I change my delivery address?', answer: 'You can select or add an address before placing the order.'),
                Divider(height: 1),
                _FaqTile(title: 'What payment methods are accepted?', answer: 'The prototype includes Cash on Delivery, GCash, Maya, and card payments.'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _openContact(context, 'Order concern'),
            icon: const Icon(Icons.support_agent_rounded),
            label: const Text('Contact Support'),
          ),
          const SizedBox(height: 12),
          Text(
            'Support hours: Monday to Saturday, 8 AM–6 PM',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _openContact(BuildContext context, String topic) {
    Navigator.of(context).pushNamed(AppRoutes.contactSupport, arguments: topic);
  }
}

class _HelpTopic extends StatelessWidget {
  const _HelpTopic({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 34, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 10),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.title, required this.answer});

  final String title;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [Align(alignment: Alignment.centerLeft, child: Text(answer))],
    );
  }
}
