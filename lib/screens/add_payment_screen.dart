import 'package:flutter/material.dart';

import '../models/product.dart';
import '../state/app_state.dart';
import '../widgets/app_widgets.dart';

class AddPaymentScreen extends StatefulWidget {
  const AddPaymentScreen({super.key});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController(text: 'Juan Dela Cruz');
  final TextEditingController _number = TextEditingController(text: '4242 4242 4242 1234');
  final TextEditingController _expiry = TextEditingController(text: '08/29');
  final TextEditingController _cvv = TextEditingController(text: '123');
  bool _cardMode = true;

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    _expiry.dispose();
    _cvv.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MobileScaffold(
      appBar: const ScreenTitleBar(title: 'Add Payment Method'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Card'), icon: Icon(Icons.credit_card_rounded)),
                  ButtonSegment(value: false, label: Text('E-wallet'), icon: Icon(Icons.account_balance_wallet_rounded)),
                ],
                selected: {_cardMode},
                onSelectionChanged: (selection) => setState(() => _cardMode = selection.first),
              ),
              const SizedBox(height: 20),
              if (_cardMode) ...[
                TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Cardholder name'), validator: _required),
                const SizedBox(height: 14),
                TextFormField(controller: _number, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Card number'), validator: _required),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: TextFormField(controller: _expiry, decoration: const InputDecoration(labelText: 'Expiry date'), validator: _required)),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(controller: _cvv, keyboardType: TextInputType.number, obscureText: true, decoration: const InputDecoration(labelText: 'CVV'), validator: _required)),
                  ],
                ),
              ] else ...[
                DropdownButtonFormField<String>(
                  value: 'GCash',
                  decoration: const InputDecoration(labelText: 'E-wallet provider'),
                  items: const [
                    DropdownMenuItem(value: 'GCash', child: Text('GCash')),
                    DropdownMenuItem(value: 'Maya', child: Text('Maya')),
                  ],
                  onChanged: (_) {},
                ),
                const SizedBox(height: 14),
                TextFormField(controller: _number, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile number'), validator: _required),
              ],
              const SizedBox(height: 18),
              AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_rounded, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 10),
                    const Expanded(child: Text('SmileHub uses secure processing for card and e-wallet payments.')),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: () {
                  if (!(_formKey.currentState?.validate() ?? false)) return;
                  final String lastFour = _number.text.replaceAll(' ', '').padLeft(4, '0');
                  AppScope.read(context).addPaymentMethod(
                    PaymentMethodItem(
                      title: _cardMode ? 'Visa ending ${lastFour.substring(lastFour.length - 4)}' : 'GCash',
                      subtitle: _cardMode ? 'Expires ${_expiry.text}' : 'Connected e-wallet',
                      icon: _cardMode ? Icons.credit_card_rounded : Icons.account_balance_wallet_rounded,
                    ),
                  );
                  showAppSnackBar(context, 'Payment method added.');
                  Navigator.of(context).pop();
                },
                child: const Text('Add Payment Method'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'This field is required' : null;
  }
}
