import 'package:flutter/material.dart';

import '../services/address_service.dart';
import '../widgets/app_widgets.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({
    super.key,
    this.addressId,
    this.initialData,
  });

  final String? addressId;
  final Map<String, dynamic>? initialData;

  bool get isEditing => addressId != null;

  @override
  State<AddAddressScreen> createState() =>
      _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final AddressService _addressService = AddressService();

  final TextEditingController _recipient =
      TextEditingController();

  final TextEditingController _mobile =
      TextEditingController();

  final TextEditingController _city =
      TextEditingController();

  final TextEditingController _barangay =
      TextEditingController();

  final TextEditingController _street =
      TextEditingController();

  final TextEditingController _postal =
      TextEditingController();

  static const List<String> _labels = <String>[
    'Home',
    'Clinic',
    'Office',
  ];

  String _label = 'Home';
  bool _isDefault = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final Map<String, dynamic>? data =
        widget.initialData;

    if (data == null) {
      return;
    }

    final String savedLabel =
        data['label']?.toString() ?? 'Home';

    _label = _labels.contains(savedLabel)
        ? savedLabel
        : 'Home';

    _recipient.text =
        data['recipient']?.toString() ?? '';

    _mobile.text =
        data['phone']?.toString() ?? '';

    _city.text =
        data['city']?.toString() ?? '';

    _barangay.text =
        data['barangay']?.toString() ?? '';

    _street.text =
        data['street']?.toString() ?? '';

    _postal.text =
        data['postalCode']?.toString() ?? '';

    _isDefault = data['isDefault'] == true;
  }

  @override
  void dispose() {
    _recipient.dispose();
    _mobile.dispose();
    _city.dispose();
    _barangay.dispose();
    _street.dispose();
    _postal.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }

    return null;
  }

  Future<void> _saveAddress() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.isEditing) {
        await _addressService.updateAddress(
          addressId: widget.addressId!,
          label: _label,
          recipient: _recipient.text.trim(),
          phone: _mobile.text.trim(),
          city: _city.text.trim(),
          barangay: _barangay.text.trim(),
          street: _street.text.trim(),
          postalCode: _postal.text.trim(),
          isDefault: _isDefault,
        );
      } else {
        await _addressService.addAddress(
          label: _label,
          recipient: _recipient.text.trim(),
          phone: _mobile.text.trim(),
          city: _city.text.trim(),
          barangay: _barangay.text.trim(),
          street: _street.text.trim(),
          postalCode: _postal.text.trim(),
          isDefault: _isDefault,
        );
      }

      if (!mounted) return;

      showAppSnackBar(
        context,
        widget.isEditing
            ? 'Address updated successfully.'
            : 'Shipping address saved successfully.',
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      showAppSnackBar(
        context,
        widget.isEditing
            ? 'Unable to update address.'
            : 'Unable to save address.',
      );

      debugPrint('ADDRESS SAVE ERROR: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MobileScaffold(
      appBar: ScreenTitleBar(
        title: widget.isEditing
            ? 'Edit Address'
            : 'Add New Address',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          18,
          8,
          18,
          28,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _label,
                decoration: const InputDecoration(
                  labelText: 'Address label',
                  prefixIcon: Icon(
                    Icons.bookmark_outline_rounded,
                  ),
                ),
                items: _labels
                    .map(
                      (String label) =>
                          DropdownMenuItem<String>(
                        value: label,
                        child: Text(label),
                      ),
                    )
                    .toList(),
                onChanged: _isSaving
                    ? null
                    : (String? value) {
                        if (value == null) return;

                        setState(() {
                          _label = value;
                        });
                      },
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _recipient,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Recipient name',
                  prefixIcon: Icon(
                    Icons.person_outline_rounded,
                  ),
                ),
                validator: _required,
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _mobile,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Mobile number',
                  prefixIcon: Icon(
                    Icons.phone_outlined,
                  ),
                ),
                validator: (String? value) {
                  final String digits = value
                          ?.replaceAll(
                            RegExp(r'[^0-9]'),
                            '',
                          ) ??
                      '';

                  if (digits.length < 10) {
                    return 'Enter a valid mobile number';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _city,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Region / City',
                  prefixIcon: Icon(
                    Icons.location_city_outlined,
                  ),
                ),
                validator: _required,
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _barangay,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Barangay',
                  prefixIcon: Icon(
                    Icons.map_outlined,
                  ),
                ),
                validator: _required,
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _street,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Street, building, unit',
                  prefixIcon: Icon(
                    Icons.home_outlined,
                  ),
                ),
                validator: _required,
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _postal,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) {
                  if (!_isSaving) {
                    _saveAddress();
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Postal code',
                  prefixIcon: Icon(
                    Icons.markunread_mailbox_outlined,
                  ),
                ),
                validator: _required,
              ),

              const SizedBox(height: 10),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Set as default address',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: const Text(
                  'Use this address during checkout.',
                ),
                value: _isDefault,
                onChanged: _isSaving
                    ? null
                    : (bool value) {
                        setState(() {
                          _isDefault = value;
                        });
                      },
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed:
                    _isSaving ? null : _saveAddress,
                child: Text(
                  _isSaving
                      ? 'Saving...'
                      : widget.isEditing
                          ? 'Save Changes'
                          : 'Save Address',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}