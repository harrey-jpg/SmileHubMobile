import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/address_service.dart';
import '../widgets/app_widgets.dart';
import 'add_address_screen.dart';

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({
    super.key,
    this.selectionMode = false,
  });

  final bool selectionMode;
  Future<void> _editAddress(
  BuildContext context,
  QueryDocumentSnapshot<Map<String, dynamic>> document,
) async {
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AddAddressScreen(
        addressId: document.id,
        initialData: document.data(),
      ),
    ),
  );
}

Future<void> _deleteAddress(
  BuildContext context,
  QueryDocumentSnapshot<Map<String, dynamic>> document,
) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Delete address?'),
        content: const Text(
          'This address will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );

  if (confirmed != true) return;

  try {
    await AddressService().deleteAddress(document.id);

    if (!context.mounted) return;

    showAppSnackBar(
      context,
      'Address deleted successfully.',
    );
  } catch (error) {
    if (!context.mounted) return;

    showAppSnackBar(
      context,
      'Unable to delete address.',
    );

    debugPrint('DELETE ADDRESS ERROR: $error');
  }
}
  Future<void> _openAddAddress(BuildContext context) async {
    await Navigator.of(context).pushNamed(
      AppRoutes.addAddress,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AddressService addressService = AddressService();

    return MobileScaffold(
      appBar: const ScreenTitleBar(
        title: 'Shipping Addresses',
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: addressService.watchAddresses(),
        builder: (
          BuildContext context,
          AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
        ) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            debugPrint(
              'LOAD ADDRESS ERROR: ${snapshot.error}',
            );

            return _AddressMessage(
              icon: Icons.error_outline_rounded,
              title: 'Unable to load addresses',
              message:
                  'Check your internet connection and Firestore permissions.',
              buttonText: 'Add New Address',
              onPressed: () {
                _openAddAddress(context);
              },
            );
          }

          final List<QueryDocumentSnapshot<Map<String, dynamic>>> documents =
              List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
            snapshot.data?.docs ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[],
          );

          // Default address first.
          documents.sort(
            (
              QueryDocumentSnapshot<Map<String, dynamic>> first,
              QueryDocumentSnapshot<Map<String, dynamic>> second,
            ) {
              final bool firstDefault =
                  first.data()['isDefault'] == true;

              final bool secondDefault =
                  second.data()['isDefault'] == true;

              if (firstDefault == secondDefault) {
                return 0;
              }

              return firstDefault ? -1 : 1;
            },
          );

          if (documents.isEmpty) {
            return _AddressMessage(
              icon: Icons.location_off_outlined,
              title: 'No saved addresses',
              message:
                  'Add a delivery address before placing an order.',
              buttonText: 'Add New Address',
              onPressed: () {
                _openAddAddress(context);
              },
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              28,
            ),
            children: [
              Text(
                '${documents.length} saved '
                '${documents.length == 1 ? 'address' : 'addresses'}',
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 12),

              ...documents.map(
                (
                  QueryDocumentSnapshot<Map<String, dynamic>> document,
                ) {
                  final Map<String, dynamic> data =
                      document.data();

                  final String label =
                      _readText(data, 'label', fallback: 'Address');

                  final String recipient =
                      _readText(data, 'recipient');

                  final String phone =
                      _readText(data, 'phone');

                  final String fullAddress =
                      _getFullAddress(data);

                  final bool isDefault =
                      data['isDefault'] == true;

                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: AppCard(
                      onTap: selectionMode
                          ? () {
                              Navigator.of(context).pop(
                                <String, dynamic>{
                                  'addressId': document.id,
                                  ...data,
                                },
                              );
                            }
                          : null,
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                label == 'Clinic' ||
                                        label == 'Office'
                                    ? Icons.business_rounded
                                    : Icons.home_rounded,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary,
                              ),

                              const SizedBox(width: 8),

                              Expanded(
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontWeight:
                                        FontWeight.w900,
                                  ),
                                ),
                              ),

                              if (isDefault)
                                const Chip(
                                  label: Text('Default'),
                                ),

                              if (selectionMode) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons
                                      .radio_button_unchecked_rounded,
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 12),

                          Text(
                            recipient.isEmpty
                                ? 'No recipient name'
                                : recipient,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          if (phone.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(phone),
                          ],

                          const SizedBox(height: 4),

                          Text(
                            fullAddress.isEmpty
                                ? 'No complete address'
                                : fullAddress,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                        if (!selectionMode) ...[
  const SizedBox(height: 12),

  Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      TextButton.icon(
        onPressed: () {
          _editAddress(context, document);
        },
        icon: const Icon(
          Icons.edit_outlined,
          size: 18,
        ),
        label: const Text('Edit'),
      ),

      const SizedBox(width: 6),

      TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor:
              Theme.of(context).colorScheme.error,
        ),
        onPressed: () {
          _deleteAddress(context, document);
        },
        icon: const Icon(
          Icons.delete_outline_rounded,
          size: 18,
        ),
        label: const Text('Delete'),
      ),
    ],
  ),
],
                          if (selectionMode) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Tap to use this address',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            
              const SizedBox(height: 4),

              OutlinedButton.icon(
                onPressed: () {
                  _openAddAddress(context);
                },
                icon: const Icon(
                  Icons.add_location_alt_outlined,
                ),
                label: const Text(
                  'Add New Address',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _readText(
    Map<String, dynamic> data,
    String key, {
    String fallback = '',
  }) {
    final String value =
        data[key]?.toString().trim() ?? '';

    return value.isEmpty ? fallback : value;
  }

  static String _getFullAddress(
    Map<String, dynamic> data,
  ) {
    final String savedFullAddress =
        _readText(data, 'fullAddress');

    if (savedFullAddress.isNotEmpty) {
      return savedFullAddress;
    }

    final String street = _readText(data, 'street');
    final String barangay =
        _readText(data, 'barangay');
    final String city = _readText(data, 'city');
    final String postalCode =
        _readText(data, 'postalCode');

    return <String>[
      street,
      barangay,
      city,
      postalCode,
    ].where((String value) => value.isNotEmpty).join(', ');
  }
}

class _AddressMessage extends StatelessWidget {
  const _AddressMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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

            const SizedBox(height: 22),

            ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(
                Icons.add_location_alt_outlined,
              ),
              label: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}