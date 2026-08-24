import 'package:flutter/material.dart';

import '../widgets/app_widgets.dart';

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key, this.initialConcern = 'Order concern'});

  final String initialConcern;

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String _concern;
  final TextEditingController _orderNumber = TextEditingController(text: '#SH-2026-0148');
  final TextEditingController _email = TextEditingController(text: 'juan@example.com');
  final TextEditingController _message = TextEditingController(text: 'Please describe your concern and include useful order or product details.');

  @override
  void initState() {
    super.initState();
    const concerns = ['Order concern', 'Payment concern', 'Account help', 'Product question'];
    _concern = concerns.contains(widget.initialConcern) ? widget.initialConcern : concerns.first;
  }

  @override
  void dispose() {
    _orderNumber.dispose();
    _email.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MobileScaffold(
      appBar: const ScreenTitleBar(title: 'Contact Support'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Send us a message', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text('Our support team usually replies within one business day.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 22),
              DropdownButtonFormField<String>(
                value: _concern,
                decoration: const InputDecoration(labelText: 'Concern type'),
                items: const [
                  DropdownMenuItem(value: 'Order concern', child: Text('Order concern')),
                  DropdownMenuItem(value: 'Payment concern', child: Text('Payment concern')),
                  DropdownMenuItem(value: 'Account help', child: Text('Account help')),
                  DropdownMenuItem(value: 'Product question', child: Text('Product question')),
                ],
                onChanged: (value) => setState(() => _concern = value ?? _concern),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _orderNumber,
                decoration: const InputDecoration(labelText: 'Order number (optional)'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email address'),
                validator: (value) => value == null || !value.contains('@') ? 'Enter a valid email address' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _message,
                minLines: 5,
                maxLines: 8,
                decoration: const InputDecoration(labelText: 'Message', alignLabelWithHint: true),
                validator: (value) => value == null || value.trim().length < 10 ? 'Please provide more details' : null,
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => showAppSnackBar(context, 'Photo attachment is simulated.'),
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Attach Photo'),
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: () {
                  if (!(_formKey.currentState?.validate() ?? false)) return;
                  showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      icon: const Icon(Icons.check_circle_rounded),
                      title: const Text('Request submitted'),
                      content: const Text('Your support request was sent. This is a local UI simulation.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            Navigator.of(context).pop();
                          },
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Submit Support Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
